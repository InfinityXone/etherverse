#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Starting Full Sync Pipeline"

read -r -p "Enter GitHub repository (owner/repo): " REPO
echo "Repository set to: $REPO"

# Environment secrets (to be set via GitHub Actions or local export)
AGENT_API_KEY="${AGENT_API_KEY:-}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}"
VERCEL_TOKEN="${VERCEL_TOKEN:-}"
GITHUB_APP_PRIVATE_KEY="${GITHUB_APP_PRIVATE_KEY:-}"
GITHUB_APP_APP_ID="${GITHUB_APP_APP_ID:-}"

if [[ -z "$GITHUB_APP_PRIVATE_KEY" || -z "$GITHUB_APP_APP_ID" ]]; then
  echo "[ERR] GitHub App credentials not provided."
  exit 1
fi

echo "[*] Generating GitHub App JWT..."
JWT=$(python3 - <<'PY'
import jwt, time, os
app_id = int(os.environ["GITHUB_APP_APP_ID"])
key = os.environ["GITHUB_APP_PRIVATE_KEY"].replace("\\n", "\n")
payload = {"iat": int(time.time()) - 60, "exp": int(time.time()) + 600, "iss": app_id}
token = jwt.encode(payload, key, algorithm="RS256")
print(token if isinstance(token, str) else token.decode())
PY
)
echo "[✓] JWT generated."

echo "[*] Obtaining installation token..."
INSTALL_ID=$(curl -s -H "Authorization: Bearer $JWT" -H "Accept: application/vnd.github+json" \
  https://api.github.com/app/installations | jq -r '.[0].id')
INSTALL_TOKEN=$(curl -s -X POST -H "Authorization: Bearer $JWT" -H "Accept: application/vnd.github+json" \
  https://api.github.com/app/installations/$INSTALL_ID/access_tokens | jq -r .token)
echo "[✓] Installation token created."

echo "[*] Calling Agent Gateway..."
AGENT_RESPONSE=$(curl -s -H "Authorization: Bearer $AGENT_API_KEY" \
  -H "Content-Type: application/json" \
  -X POST "http://127.0.0.1:5053/api/run" \
  -d '{"agent":"PromptWriter","task":"Produce summary and deploy status"}')
SUMMARY=$(echo "$AGENT_RESPONSE" | jq -r .result)
echo "[✓] Agent response captured."

echo "[*] Storing to Supabase..."
curl -s -X POST "https://your-project.supabase.co/rest/v1/logs" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"summary\":\"$SUMMARY\"}"
echo "[✓] Supabase log entry created."

echo "[*] Committing results to GitHub repo..."
echo "$SUMMARY" > agent_summary.txt
git add agent_summary.txt
git commit -m "Automated summary update $(date -u +%Y-%m-%dT%H:%M:%SZ)"
GIT_TERMINAL_PROMPT=0 git push https://x-access-token:$INSTALL_TOKEN@github.com/$REPO.git
echo "[✓] GitHub repo updated."

echo "[*] Triggering Vercel Deployment..."
curl -s -X POST "https://api.vercel.com/v13/deployments" \
  -H "Authorization: Bearer $VERCEL_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"gitBranch\":\"main\"}"
echo "[✓] Vercel deployment requested."

echo "✅ Full Sync Pipeline complete."
