#!/bin/bash
set -e

# Install Docker and Docker Compose if they're not already installed
if ! command -v docker &> /dev/null; then
  echo "Installing Docker..."
  apt-get update
  apt-get install -y apt-transport-https ca-certificates curl software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io
fi

if ! command -v docker-compose &> /dev/null; then
  echo "Installing Docker Compose..."
  curl -L "https://github.com/docker/compose/releases/download/v2.23.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
fi

# Install Certbot for SSL certificates
if ! command -v certbot &> /dev/null; then
  echo "Installing Certbot..."
  apt-get update
  apt-get install -y certbot python3-certbot-nginx
fi

# Create .env file from environment variables in terraform
DOMAIN="${DOMAIN_NAME:-example.com}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-saleor}"
DB_PASSWORD="${DB_PASSWORD:-password}"
DB_NAME="${DB_NAME:-saleor}"
REDIS_HOST="redis"
REDIS_PORT="6379"
SECRET_KEY="${SECRET_KEY:-$(openssl rand -base64 32)}"
API_URL="https://${DOMAIN}/graphql/"

# Fetch Database URL from DigitalOcean Managed DB if available
if [[ -n "${DO_DATABASE_URL}" ]]; then
  echo "Using managed DigitalOcean database..."
  DATABASE_URL="${DO_DATABASE_URL}"
else
  DATABASE_URL="postgres://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
fi

# Create .env file
cat > .env << EOF
DATABASE_URL=${DATABASE_URL}
REDIS_URL=redis://${REDIS_HOST}:${REDIS_PORT}/0
SECRET_KEY=${SECRET_KEY}
ALLOWED_HOSTS=${DOMAIN},api
DEBUG=False
API_URL=${API_URL}
NEXT_PUBLIC_SALEOR_API_URL=${API_URL}
AWS_ACCESS_KEY_ID=${SPACES_ACCESS_KEY}
AWS_SECRET_ACCESS_KEY=${SPACES_SECRET_KEY}
AWS_STORAGE_BUCKET_NAME=${SPACE_NAME}
AWS_S3_ENDPOINT_URL=https://${SPACE_REGION}.digitaloceanspaces.com
AWS_S3_REGION_NAME=${SPACE_REGION}
AWS_S3_CUSTOM_DOMAIN=${SPACE_NAME}.${SPACE_REGION}.digitaloceanspaces.com
EOF

# Generate Nginx configuration based on domain
./generate_nginx_conf.sh ${DOMAIN}

# Set up SSL certificates
echo "Setting up SSL certificates with Let's Encrypt..."
certbot --nginx -d ${DOMAIN} --non-interactive --agree-tos --email admin@${DOMAIN} --redirect

# Pull latest Docker images
echo "Pulling Docker images..."
docker-compose pull

# Apply initial database migrations
echo "Running database migrations..."
docker-compose up -d api
docker-compose exec -T api python manage.py migrate

# Create initial superuser
echo "Creating initial superuser..."
cat > create_superuser.py << EOF
import os
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "saleor.settings")
import django
django.setup()
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(email='admin@${DOMAIN}').exists():
    User.objects.create_superuser('admin@${DOMAIN}', 'admin123')
    print("Superuser created successfully")
else:
    print("Superuser already exists")
EOF
docker-compose exec -T api python -c "$(cat create_superuser.py)"
rm create_superuser.py

# Start all services
echo "Starting all services..."
docker-compose up -d

# Enable automatic security updates
echo "Enabling automatic security updates..."
apt-get install -y unattended-upgrades
cat > /etc/apt/apt.conf.d/20auto-upgrades << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

echo "Setup complete - Saleor is now running at https://${DOMAIN}"
echo "Dashboard available at: https://${DOMAIN}/dashboard/"
echo "Admin credentials: admin@${DOMAIN} / admin123"
echo "IMPORTANT: Please change the default admin password immediately!"
