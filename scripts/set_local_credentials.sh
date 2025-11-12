#!/usr/bin/env bash  
set -euo pipefail  

CONFIG_PATH="$HOME/.config/etherverse/credentials.json"  
mkdir -p "$(dirname "$CONFIG_PATH")"  
chmod 700 "$(dirname "$CONFIG_PATH")"  

echo "🔐 Interactive Local Credentials Setup"

read -rp "Enter GitHub App ID: " GITHUB_APP_APP_ID  
while [[ -z "$GITHUB_APP_APP_ID" ]]; do  
  echo "[ERROR] GitHub App ID cannot be empty. Try again."  
  read -rp "Enter GitHub App ID: " GITHUB_APP_APP_ID  
done  

echo "Paste your GitHub App Private Key (PEM format). End with Ctrl+D:"  
GITHUB_APP_PRIVATE_KEY=$(</dev/stdin)  
# Basic format check  
if ! grep -q "-----BEGIN.*PRIVATE KEY-----" <<< "$GITHUB_APP_PRIVATE_KEY"; then  
  echo "[ERROR] The key format looks invalid (missing BEGIN/END lines). Exiting."  
  exit 1  
fi  

read -rp "Enter Agent API Key: " AGENT_API_KEY  
while [[ -z "$AGENT_API_KEY" ]]; do  
  echo "[ERROR] Agent API Key cannot be empty. Try again."  
  read -rp "Enter Agent API Key: " AGENT_API_KEY  
done  

read -rp "Enter Supabase ANON Key: " SUPABASE_ANON_KEY  
while [[ -z "$SUPABASE_ANON_KEY" ]]; do  
  echo "[ERROR] Supabase ANON Key cannot be empty. Try again."  
  read -rp "Enter Supabase ANON Key: " SUPABASE_ANON_KEY  
done  

read -rp "Enter Vercel Token: " VERCEL_TOKEN  
while [[ -z "$VERCEL_TOKEN" ]]; do  
  echo "[ERROR] Vercel Token cannot be empty. Try again."  
  read -rp "Enter Vercel Token: " VERCEL_TOKEN  
done  

# Write config file  
cat > "$CONFIG_PATH" <<EOF  
{  
  "github_app": {  
    "app_id": $GITHUB_APP_APP_ID,  
    "private_key": "$(echo "$GITHUB_APP_PRIVATE_KEY" | sed ':a;N;\$!ba;s/"/\\"/g')"  
  },  
  "agent_gateway": {  
    "api_key": "$AGENT_API_KEY"  
  },  
  "supabase": {  
    "anon_key": "$SUPABASE_ANON_KEY"  
  },  
  "vercel": {  
    "token": "$VERCEL_TOKEN"  
  }  
}  
EOF  

chmod 600 "$CONFIG_PATH"  
echo "[✓] Credentials stored locally at $CONFIG_PATH"  
