#!/bin/bash
set -e

# Check if domain was provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <domain>"
    exit 1
fi

DOMAIN="$1"

# Load environment variables from .env file if it exists
if [ -f .env ]; then
    echo "Loading environment variables from .env file..."
    export $(grep -v '^#' .env | xargs)
fi

# Check for required variables
if [ -z "$AWS_S3_ENDPOINT_URL" ] || [ -z "$AWS_STORAGE_BUCKET_NAME" ] || [ -z "$AWS_S3_CUSTOM_DOMAIN" ]; then
    echo "Warning: Missing S3/Spaces configuration. Media URLs may not work correctly."
    # Set defaults to prevent template errors
    AWS_S3_ENDPOINT_URL=${AWS_S3_ENDPOINT_URL:-"https://example.com"}
    AWS_STORAGE_BUCKET_NAME=${AWS_STORAGE_BUCKET_NAME:-"bucket"}
    AWS_S3_CUSTOM_DOMAIN=${AWS_S3_CUSTOM_DOMAIN:-"example.com"}
fi

# Create Nginx configuration from template
echo "Generating Nginx configuration for domain: $DOMAIN"
cat nginx.conf.template | \
    SERVER_NAME="$DOMAIN" \
    AWS_S3_ENDPOINT_URL="$AWS_S3_ENDPOINT_URL" \
    AWS_STORAGE_BUCKET_NAME="$AWS_STORAGE_BUCKET_NAME" \
    AWS_S3_CUSTOM_DOMAIN="$AWS_S3_CUSTOM_DOMAIN" \
    envsubst '${SERVER_NAME} ${AWS_S3_ENDPOINT_URL} ${AWS_STORAGE_BUCKET_NAME} ${AWS_S3_CUSTOM_DOMAIN}' > nginx.conf

echo "Nginx configuration generated successfully at nginx.conf"

# Ensure the letsencrypt webroot directory exists
mkdir -p /var/www/letsencrypt/.well-known/acme-challenge

echo "Created Let's Encrypt webroot directory"


Set up SSL with Certbot:


sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
sudo certbot --nginx -d yourdomain.com


probably we need to store certificates in bucket to avoid losing them and regenerate them

docker compose exec api saleor migrate
docker compose exec api saleor createsuperuser


Environment Variables Table
Below is a table of key environment variables for Saleor Core, based on documentation:

Variable	Description	Example Value
SERVER_NAME	Domain name for Nginx configuration	yourdomain.com
DATABASE_URL	PostgreSQL connection URL	postgres://doadmin:password@host:25060/dbname?sslmode=require
REDIS_URL	Redis URL for caching and Celery	redis://redis:6379/0
SECRET_KEY	Security key for Django	Random string
ALLOWED_HOSTS	Domain names allowed	yourdomain.com
DEBUG	Enable/disable debug mode	False (for production)
API_URL	URL for GraphQL API endpoint	https://yourdomain.com/graphql/
AWS_ACCESS_KEY_ID	AWS access key for Spaces storage	Your Spaces access key
AWS_SECRET_ACCESS_KEY	AWS secret access key for Spaces storage	Your Spaces secret key
AWS_STORAGE_BUCKET_NAME	Spaces bucket name for media files	Your Space name
AWS_S3_ENDPOINT_URL	Endpoint URL for Spaces	https://nyc3.digitaloceanspaces.com
AWS_S3_REGION_NAME	Region name for Spaces	nyc3