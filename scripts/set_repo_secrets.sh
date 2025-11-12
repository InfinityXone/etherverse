#!/usr/bin/env bash
set -euo pipefail

echo "🔐 GitHub Repository Secrets Setup"

read -r -p "Enter GitHub repository (owner/repo): " REPO

declare -a secret_names=(
  "AGENT_API_KEY"
  "SUPABASE_ANON_KEY"
  "VERCEL_TOKEN"
  "GITHUB_APP_PRIVATE_KEY"
  "GITHUB_APP_APP_ID"
)

for secret in "${secret_names[@]}"; do
  read -r -p "Enter value for secret ${secret}: " value
  echo "Setting secret ${secret} on ${REPO}..."
  gh secret set "${secret}" --repo "${REPO}" --body "${value}"
done

echo "✅ All secrets set successfully for ${REPO}"
