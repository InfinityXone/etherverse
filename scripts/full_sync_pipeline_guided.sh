#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Guided Full-Sync Pipeline"

read -r -p "Enter GitHub repository (owner/repo): " REPO
echo "Repository: $REPO"

# Check GitHub CLI login
if ! gh auth status >/dev/null 2>&1; then
  echo "[WARN] You are not logged into GitHub CLI."
  echo "Run: gh auth login"
  exit 1
fi

# Prompt for GitHub App credentials if missing
if [[ -z "${GITHUB_APP_APP_ID:-}" ]]; then
  read -r -p "Enter GitHub App ID: " GITHUB_APP_APP_ID
fi
if [[ -z "${GITHUB_APP_PRIVATE_KEY:-}" ]]; then
  echo "Paste your GitHub App Private Key (PEM format). End with Ctrl+D:"
  GITHUB_APP_PRIVATE_KEY=$(</dev/stdin)
fi

export GITHUB_APP_APP_ID
export GITHUB_APP_PRIVATE_KEY

echo "[✓] GitHub App credentials captured."

# Check other required secrets
: "${AGENT_API_KEY:?Missing AGENT_API_KEY. Please set environment variable or secret.}"
: "${SUPABASE_ANON_KEY:?Missing SUPABASE_ANON_KEY. Please set environment variable or secret.}"
: "${VERCEL_TOKEN:?Missing VERCEL_TOKEN. Please set environment variable or secret.}"

echo "[✓] All required secrets present."

# Generate GitHub App JWT
echo "[*] Generating GitHub App JWT..."
JWT=$(python3 - <<'PY'
import jwt, time, os
app_id = int(os.environ["GITHUB_APP_APP_ID"])
key = os.environ["GITHUB_APP_PRIVATE_KEY"]
payload = {"iat": int(time.time())-60, "exp": int(time.time())+600, "iss": app_id}
token = jwt.encode(payload, key, algorithm="RS256")
print(token if isinstance(token, str) else token.decode())
PY
)
echo "[✓] JWT generated."

# Obtain installation token
echo "[*] Obtaining installation token..."
INSTALL_ID=$(curl -s -H "Authorization: Bearer $JWT" -H "Accept: application/vnd.github+json" \
  https://api.github.com/app/installations | jq -r '.[0].id')
INSTALL_TOKEN=$(curl -s -X POST -H "Authorization: Bearer $JWT" -H "Accept: application/vnd.github+json" \
  https://api.github.com/app/installations/$INSTALL_ID/access_tokens | jq -r .token)
export INSTALL_TOKEN
echo "[✓] Installation token ready."

# Agent gateway call
echo "[*] Calling agent gateway..."
AGENT_RESPONSE=$(curl -s -H "Authorization: Bearer $AGENT_API_KEY" \
  -H "Content-Type: application/json" \
  -X POST "http://127.0.0.1:5053/api/run" \
  -d '{"agent":"PromptWriter","task":"Generate system sync summary"}')
SUMMARY=$(echo "$AGENT_RESPONSE" | jq -r .result || echo "no_result")
echo "[✓] Agent response captured."

# Log to Supabase
echo "[*] Logging to Supabase..."
curl -s -X POST "https://your-project.supabase.co/rest/v1/logs" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"summary\":\"$SUMMARY\"}"
echo "[✓] Logged summary."

# Commit result to repo
echo "[*] Committing summary to GitHub..."
echo "$SUMMARY" > agent_summary.txt
git add agent_summary.txt
git commit -m "Automated summary update $(date -u +%Y-%m-%dT%H:%M:%SZ)"
git push https://x-access-token:$INSTALL_TOKEN@github.com/$REPO.git main
echo "[✓] Push complete."

# Trigger Vercel deploy
echo "[*] Triggering Vercel deployment..."
curl -s -X POST "https://api.vercel.com/v13/deployments" \
  -H "Authorization: Bearer $VERCEL_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"gitBranch\":\"main\"}"
echo "[✓] Vercel deploy requested."

echo "✅ Guided Full-Sync Pipeline complete."
