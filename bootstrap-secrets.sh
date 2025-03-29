#!/bin/bash

set -e

# Validate dependencies
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

# Get required input
read -p "Enter your domain name (e.g., example.com): " DOMAIN_NAME
read -p "Enter region (e.g., nyc3): " REGION

# Generate SSH key
KEY_NAME="saleor-key"
KEY_PATH="$HOME/.ssh/saleor_id_rsa"
if [[ ! -f "$KEY_PATH" ]]; then
  echo "🔐 Generating SSH key..."
  ssh-keygen -t rsa -b 4096 -f "$KEY_PATH" -N "" -C "saleor@infra"
fi

PUB_KEY=$(cat "$KEY_PATH.pub")

# Upload SSH public key to DigitalOcean
echo "🌐 Uploading SSH key to DigitalOcean..."
KEY_ID=$(doctl compute ssh-key import "$KEY_NAME" --public-key "$PUB_KEY" --output json | jq -r '.[0].id')

# Get fingerprint
FINGERPRINT=$(ssh-keygen -lf "$KEY_PATH.pub" | awk '{print $2}')

# Generate Spaces key
echo "📦 Generating Spaces access keys..."
SPACES_KEYS=$(doctl iam oauth-token | jq -r .access_token | \
  xargs -I{} curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer {}" \
    -d '{"name": "saleor-spaces-key"}' \
    https://api.digitalocean.com/v2/account/keys)

ACCESS_KEY=$(echo $SPACES_KEYS | jq -r '.key.access_key')
SECRET_KEY=$(echo $SPACES_KEYS | jq -r '.key.secret_key')

# Base64 encode private key
SSH_KEY_BASE64=$(base64 "$KEY_PATH" | tr -d '\n')

# Set secrets in GitHub
echo "🚀 Pushing secrets to GitHub repo: $REPO"
gh secret set DO_REGION --repo "$REPO" --body "$REGION"
gh secret set SPACE_REGION --repo "$REPO" --body "$REGION"
gh secret set DOMAIN_NAME --repo "$REPO" --body "$DOMAIN_NAME"
gh secret set SSH_KEY --repo "$REPO" --body "$SSH_KEY_BASE64"
gh secret set SSH_KEY_FINGERPRINT --repo "$REPO" --body "$FINGERPRINT"
gh secret set SPACES_ACCESS_KEY --repo "$REPO" --body "$ACCESS_KEY"
gh secret set SPACES_SECRET_KEY --repo "$REPO" --body "$SECRET_KEY"

echo "✅ Bootstrap complete! All secrets set and ready for deployment."
