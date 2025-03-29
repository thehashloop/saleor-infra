#!/bin/bash

# Load .env variables
set -a
source .env
set +a

# Generate nginx.conf from template
envsubst '${SERVER_NAME}' < nginx.conf.template > nginx.conf


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