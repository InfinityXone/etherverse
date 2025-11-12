#!/usr/bin/env bash
set -euo pipefail

CONFIG="$HOME/etherverse/config/credentials.json"
GATEWAY_URL="$(jq -r .agent_gateway.url "$CONFIG")"
AGENT_API_KEY_ENV="$(jq -r .agent_gateway.api_key_env "$CONFIG")"
SUPABASE_URL="$(jq -r .supabase.url "$CONFIG")"
SUPABASE_KEY_ENV="$(jq -r .supabase.anon_key_env "$CONFIG")"
VERCEL_TOKEN_ENV="$(jq -r .vercel.token_env "$CONFIG")"
REPO_OWNER="InfinityXone"
REPO_NAME="etherverse"
BRANCH="main"

# GitHub App JWT and installation token
APP_ID="$(jq -r .github_app.app_id "$CONFIG")"
KEY_PATH="$(eval echo $(jq -r .github_app.private_key_path "$CONFIG"))"

JWT=$(python3 - <<'PY'
import jwt, time, json, pathlib, os
cfg=pathlib.Path(os.path.expanduser("${CONFIG}"))
data=json.loads(cfg.read_text())
app_id=int(data["github_app"]["app_id"])
key=pathlib.Path(os.path.expanduser(data["github_app"]["private_key_path"])).read_text()
payload={"iat":int(time.time())-60,"exp":int(time.time())+600,"iss":app_id}
token=jwt.encode(payload, key, algorithm="RS256")
print(token if isinstance(token,str) else token.decode())
PY
)
echo "[✓] JWT generated."

INSTALL_ID=$(curl -s -H "Authorization: Bearer $JWT" -H "Accept: application/vnd.github+json" \
  https://api.github.com/app/installations | jq -r '.[0].id')

TOKEN_APP=$(curl -s -X POST -H "Authorization: Bearer $JWT" -H "Accept: application/vnd.github+json" \
  https://api.github.com/app/installations/$INSTALL_ID/access_tokens | jq -r .token)
echo "[✓] GitHub App installation token created."

# Agent gateway call
AGENT_API_KEY="${!AGENT_API_KEY_ENV}"
curl -s -H "Authorization: Bearer $AGENT_API_KEY" -H "Content-Type: application/json" \
  -X POST "$GATEWAY_URL/run" -d '{"agent":"PromptWriter","task":"generate deployment summary"}' \
  | tee agent_output.json
echo "[✓] Agent gateway call complete."

# Supabase write
SUPABASE_KEY="${!SUPABASE_KEY_ENV}"
SUMMARY="$(jq -r .result agent_output.json || echo "no_result")"
curl -s -X POST "$SUPABASE_URL/rest/v1/logs" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"summary\":\"$SUMMARY\"}"
echo "[✓] Supabase log written."

# Commit summary to GitHub repo
echo "$SUMMARY" > integration_summary.txt
git add integration_summary.txt
GIT_TERMINAL_PROMPT=0 git commit -m "Agent summary update $(date -u +%Y-%m-%dT%H:%M:%SZ)"
git push https://x-access-token:$TOKEN_APP@github.com/$REPO_OWNER/$REPO_NAME.git $BRANCH
echo "[✓] Repo updated via GitHub App token."

# Trigger Vercel deploy
VERCEL_TOKEN="${!VERCEL_TOKEN_ENV}"
curl -s -X POST "https://api.vercel.com/v13/deployments" \
  -H "Authorization: Bearer $VERCEL_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"gitBranch\":\"$BRANCH\"}"
echo "[✓] Vercel deployment triggered."

echo "[ALL DONE] Full sync run complete."
