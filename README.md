# Saleor Infrastructure for Small Business

This repository contains the infrastructure code to deploy a production-ready Saleor e-commerce platform on DigitalOcean. This setup is optimized for small businesses with up to 100 users per day.

## Architecture

The infrastructure includes:
- DigitalOcean Droplet for hosting the application
- Managed PostgreSQL database
- DigitalOcean Spaces for media storage
- Redis for caching and message queue
- HTTPS with Let's Encrypt SSL certificates
- Nginx as a reverse proxy and load balancer

## Prerequisites

You will need:
- A DigitalOcean account
- A domain name pointed to DigitalOcean nameservers
- GitHub CLI (`gh`)
- DigitalOcean CLI (`doctl`)
- `jq` for JSON processing

### Installing Prerequisites

```bash
# On Ubuntu/Debian
sudo apt install jq -y

# Install GitHub CLI
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh -y

# Install DigitalOcean CLI
curl -sL https://github.com/digitalocean/doctl/releases/download/v1.101.0/doctl-1.101.0-linux-amd64.tar.gz | tar -xzv
sudo mv doctl /usr/local/bin
```

## Initial Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/saleor-infra.git
   cd saleor-infra
   ```

2. Clone the Saleor storefront repository:
   ```bash
   git clone https://github.com/saleor/storefront.git saleor-storefront
   ```

3. Make sure the Dockerfile exists in the saleor-storefront directory:
   ```
   FROM node:18
   WORKDIR /app
   COPY package*.json ./
   RUN npm install
   COPY . .
   ARG NEXT_PUBLIC_SALEOR_API_URL
   ENV NEXT_PUBLIC_SALEOR_API_URL=$NEXT_PUBLIC_SALEOR_API_URL
   RUN npm run build
   CMD ["npm", "start"]
   ```

4. Make the bootstrap script executable:
   ```bash
   chmod +x bootstrap-secrets.sh
   ```

5. Run the bootstrap script to set up required secrets in GitHub:
   ```bash
   ./bootstrap-secrets.sh
   ```
   
   Follow the prompts to input your:
   - Domain name
   - DigitalOcean region
   - DigitalOcean API token
   - DigitalOcean Spaces Access Key and Secret Key

## Deployment

The deployment happens automatically via GitHub Actions when you push to the main branch. 

To manually trigger a deployment, go to the GitHub repository's Actions tab and run the "Deploy Saleor Infrastructure" workflow manually.

## Post-Deployment

After the initial deployment, you should:

1. Access the Saleor Dashboard at `https://yourdomain.com/dashboard/`
2. Log in with the default admin credentials (check the output of the setup script)
3. Immediately change the admin password
4. Configure your store settings:
   - Payment gateways
   - Shipping methods
   - Products and categories
   - Tax settings

## Monitoring and Maintenance

### Logs

To view application logs:
```bash
ssh root@your-droplet-ip
cd /root/docker
docker-compose logs -f api
```

### Backups

Database backups are automatically managed by DigitalOcean's managed database service. You can also perform manual backups:

```bash
# On the droplet
cd /root/docker
docker-compose exec api python manage.py dumpdata > saleor_backup_$(date +%F).json
```

### Updates

To update Saleor to a newer version:

1. Update the version tags in the `docker-compose.yml` file
2. Commit and push the changes to trigger a new deployment
3. Monitor the GitHub Actions workflow for successful deployment

## Scaling

For scaling beyond 100 users per day:

1. Increase the droplet size in the Terraform configuration (`TF_VAR_droplet_size`)
2. Consider setting up a multi-node cluster with Kubernetes
3. Add a Content Delivery Network (CDN) for assets and media files

## Troubleshooting

### Common Issues

- **SSL Certificate Issues**: If Let's Encrypt certificates are not being issued correctly, check that your domain DNS is properly configured.
- **Database Connection Issues**: Verify that the database firewall allows connections from your droplet's IP address.
- **Storage Issues**: Check that the Spaces access keys have the correct permissions.

For additional help, check the [Saleor documentation](https://docs.saleor.io/) or open an issue in this repository.

## Security Considerations

This setup includes:
- HTTPS with strong SSL settings
- Database firewall to restrict access
- Automatic security updates for the host system
- Docker containers with restart policies
- Health checks for all services

## License

This infrastructure code is licensed under MIT.