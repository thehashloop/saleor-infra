#!/bin/bash

set -e

# Dynamically get GitHub repo in the format "owner/repo"
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)

if [[ -z "$REPO" ]]; then
  echo "❌ Failed to determine the GitHub repository. Make sure you're running this from inside a cloned repo directory."
  exit 1
fi

# Prompt for secrets
read -p "Enter your DigitalOcean Token (DO_TOKEN): " DO_TOKEN
read -p "Enter your SSH key fingerprint (SSH_KEY_FINGERPRINT): " SSH_KEY_FINGERPRINT
read -p "Enter your domain (DOMAIN_NAME): " DOMAIN_NAME
read -p "Enter your DigitalOcean Space name (SPACE_NAME): " SPACE_NAME
read -p "Enter your Space region (SPACE_REGION, e.g., nyc3): " SPACE_REGION
read -p "Enter your DigitalOcean region (DO_REGION, e.g., nyc3): " DO_REGION

echo "📥 Reading private SSH key from ~/.ssh/id_rsa..."
if [[ ! -f ~/.ssh/id_rsa ]]; then
  echo "❌ SSH private key not found at ~/.ssh/id_rsa"
  exit 1
fi
SSH_KEY=$(cat ~/.ssh/id_rsa | base64 | tr -d '\n')

# Check for GH CLI
if ! command -v gh &> /dev/null; then
  echo "❌ GitHub CLI (gh) not found. Please install it first: https://cli.github.com/"
  exit 1
fi

# Ensure user is authenticated
if ! gh auth status &> /dev/null; then
  echo "🔐 You must authenticate GH CLI before running this script."
  gh auth login
fi

echo "🚀 Setting secrets in GitHub repo: $REPO"

gh secret set DO_TOKEN --repo "$REPO" --body "$DO_TOKEN"
gh secret set SSH_KEY --repo "$REPO" --body "$SSH_KEY"
gh secret set SSH_KEY_FINGERPRINT --repo "$REPO" --body "$SSH_KEY_FINGERPRINT"
gh secret set DOMAIN_NAME --repo "$REPO" --body "$DOMAIN_NAME"
gh secret set SPACE_NAME --repo "$REPO" --body "$SPACE_NAME"
gh secret set SPACE_REGION --repo "$REPO" --body "$SPACE_REGION"
gh secret set DO_REGION --repo "$REPO" --body "$DO_REGION"

echo "✅ All secrets set successfully in $REPO"
