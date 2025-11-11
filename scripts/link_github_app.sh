#!/usr/bin/env bash
# ==========================================================
#  GitHub App Automation Utility
#  Reads ~/.config/github-apps/github_app/credentials.json
#  Generates JWT + installation token and verifies access.
# ==========================================================
set -euo pipefail

CONFIG="$HOME/.config/github-apps/github_app/credentials.json"

# ---------- Sanity checks ----------
if [[ ! -f "$CONFIG" ]]; then
  echo "[ERR] Config not found at $CONFIG"
  exit 1
fi

APP_ID=$(jq -r .app_id "$CONFIG")
OWNER=$(jq -r .owner "$CONFIG")
REPO_LIST=$(jq -r '.repositories[]' "$CONFIG")
KEY_PATH=$(eval echo $(jq -r .private_key_path "$CONFIG"))

echo "[*] Using key at: $KEY_PATH"
echo "[*] App ID: $APP_ID | Owner: $OWNER"
echo "[*] Target repos: $REPO_LIST"

if [[ ! -f "$KEY_PATH" ]]; then
  echo "[ERR] Private key not found at $KEY_PATH"
  exit 1
fi

# ---------- Generate JWT ----------
echo "[*] Generating JWT..."
JWT=$(python3 - <<'PY'
import jwt, time, os, json, pathlib

cfg = str(pathlib.Path.home() / ".config/github-apps/github_app/credentials.json")
with open(cfg) as f:
    data = json.load(f)

app_id = int(data["app_id"])
key_path = os.path.expanduser(data["private_key_path"])
with open(key_path) as f:
    key = f.read()

payload = {
    "iat": int(time.time()) - 60,
    "exp": int(time.time()) + 600,
    "iss": app_id
}

token = jwt.encode(payload, key, algorithm="RS256")
print(token if isinstance(token, str) else token.decode())
PY
)
echo "[✓] JWT generated."

# ---------- Create installation token ----------
echo "[*] Requesting installation token..."
INSTALL_ID=$(curl -s \
  -H "Authorization: Bearer $JWT" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/app/installations | jq -r '.[0].id')

if [[ "$INSTALL_ID" == "null" || -z "$INSTALL_ID" ]]; then
  echo "[ERR] Unable to retrieve installation ID."
  exit 1
fi

TOKEN=$(curl -s -X POST \
  -H "Authorization: Bearer $JWT" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/app/installations/$INSTALL_ID/access_tokens | jq -r .token)

if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
  echo "[ERR] Failed to create installation token."
  exit 1
fi
echo "[✓] Installation token created."

# ---------- Verify by listing accessible repositories ----------
echo "[*] Verifying repository access..."
curl -s \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/installation/repositories | jq -r '.repositories[].full_name'

echo "[✅] GitHub App access verified."

# ---------- Optional: demonstrate quick API call ----------
echo "[*] Example API call: showing open issues for first target repo..."
FIRST_REPO=$(echo "$REPO_LIST" | head -n 1)
curl -s \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/${OWNER}/${FIRST_REPO}/issues?state=open | jq -r '.[].title'

echo "[✅] Script completed successfully."
