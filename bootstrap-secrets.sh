#!/bin/bash

set -e

# Check dependencies
for cmd in gh doctl jq; do
  if ! command -v $cmd &> /dev/null; then
    echo "❌ Missing dependency: $cmd"
    exit 1
  fi
done

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)
if [[ -z "$REPO" ]]; then
  echo "❌ Must be inside a cloned GitHub repo directory."
  exit 1
fi

read -p "Enter your domain name (e.g., example.com): " DOMAIN_NAME
read -p "Enter region (e.g., nyc3): " REGION

# Generate SSH Key
KEY_NAME="saleor-key"
KEY_PATH="$HOME/.ssh/saleor_id_rsa"
if [[ ! -f "$KEY_PATH" ]]; then
  echo "🔐 Generating SSH key..."
  ssh-keygen -t rsa -b 4096 -f "$KEY_PATH" -N "" -C "saleor@infra"
fi

PUB_KEY=$(cat "$KEY_PATH.pub")

# Upload SSH Key to DO
echo "🌐 Uploading SSH key to DigitalOcean..."
echo "$PUB_KEY" > /tmp/temp-key.pub
KEY_ID=$(doctl compute ssh-key import "$KEY_NAME" --public-key-file /tmp/temp-key.pub --output json | jq -r '.[0].id')
rm /tmp/temp-key.pub

# Get SSH fingerprint
FINGERPRINT=$(ssh-keygen -lf "$KEY_PATH.pub" | awk '{print $2}')
SSH_KEY_BASE64=$(base64 "$KEY_PATH" | tr -d '\n')

# Prompt manually for Spaces keys (or fetch via DigitalOcean API if desired)
read -p "Enter your DigitalOcean Spaces Access Key: " ACCESS_KEY
read -p "Enter your DigitalOcean Spaces Secret Key: " SECRET_KEY

# Set GitHub Secrets
echo "🚀 Pushing secrets to GitHub repo: $REPO"
gh secret set DO_REGION --repo "$REPO" --body "$REGION"
gh secret set SPACE_REGION --repo "$REPO" --body "$REGION"
gh secret set DOMAIN_NAME --repo "$REPO" --body "$DOMAIN_NAME"
gh secret set SSH_KEY --repo "$REPO" --body "$SSH_KEY_BASE64"
gh secret set SSH_KEY_FINGERPRINT --repo "$REPO" --body "$FINGERPRINT"
gh secret set SPACES_ACCESS_KEY --repo "$REPO" --body "$ACCESS_KEY"
gh secret set SPACES_SECRET_KEY --repo "$REPO" --body "$SECRET_KEY"

echo "✅ Bootstrap complete!"
