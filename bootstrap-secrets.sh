#!/bin/bash

set -e

# Check dependencies
for cmd in gh doctl jq; do
  if ! command -v $cmd &> /dev/null; then
    echo "❌ Missing dependency: $cmd"
    exit 1
  fi
done

# Get current GitHub repo
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)
if [[ -z "$REPO" ]]; then
  echo "❌ Must be inside a cloned GitHub repo directory."
  exit 1
fi

# Prompt for inputs
read -p "Enter your domain name (e.g., example.com): " DOMAIN_NAME
read -p "Enter region (e.g., nyc3): " REGION
read -sp "Enter your DigitalOcean API token (DO_TOKEN): " DO_TOKEN && echo

# Generate SSH key
KEY_NAME="saleor-key"
KEY_PATH="$HOME/.ssh/saleor_id_rsa"
if [[ ! -f "$KEY_PATH" ]]; then
  echo "🔐 Generating SSH key..."
  ssh-keygen -t rsa -b 4096 -f "$KEY_PATH" -N "" -C "saleor@infra"
fi

PUB_KEY=$(cat "$KEY_PATH.pub")

# Upload SSH key to DigitalOcean
echo "🌐 Uploading SSH key to DigitalOcean..."
echo "$PUB_KEY" > /tmp/temp-key.pub
KEY_ID=$(doctl compute ssh-key import "$KEY_NAME" --public-key-file /tmp/temp-key.pub --output json | jq -r '.[0].id')
rm /tmp/temp-key.pub

# Get fingerprint and base64 encode private key
FINGERPRINT=$(ssh-keygen -lf "$KEY_PATH.pub" | awk '{print $2}')
SSH_KEY_BASE64=$(base64 "$KEY_PATH" | tr -d '\n')

# Prompt for Spaces Access Key and Secret Key
read -p "Enter your DigitalOcean Spaces Access Key: " ACCESS_KEY
read -p "Enter your DigitalOcean Spaces Secret Key: " SECRET_KEY

# Push secrets to GitHub
echo "🚀 Pushing secrets to GitHub repo: $REPO"
gh secret set DO_REGION --repo "$REPO" --body "$REGION"
gh secret set SPACE_REGION --repo "$REPO" --body "$REGION"
gh secret set DOMAIN_NAME --repo "$REPO" --body "$DOMAIN_NAME"
gh secret set DO_TOKEN --repo "$REPO" --body "$DO_TOKEN"
gh secret set SSH_KEY --repo "$REPO" --body "$SSH_KEY_BASE64"
gh secret set SSH_KEY_FINGERPRINT --repo "$REPO" --body "$FINGERPRINT"
gh secret set SPACES_ACCESS_KEY --repo "$REPO" --body "$ACCESS_KEY"
gh secret set SPACES_SECRET_KEY --repo "$REPO" --body "$SECRET_KEY"
gh secret set SSH_KEY_ID --repo "$REPO" --body "$KEY_ID"


echo "✅ Bootstrap complete and all secrets set for repo: $REPO"
