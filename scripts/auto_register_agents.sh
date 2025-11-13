#!/usr/bin/env bash
# ===============================================================
#  Etherverse Modular Agent Auto-Registration & Health Sync
#  Scans recursively for agents_manifest.json and updates registry
# ===============================================================
set -e

LOG_DIR="/home/etherverse/etherverse/logs"
mkdir -p "$LOG_DIR"

TMP_LOG="$LOG_DIR/agent_registry_sync.log"
REGISTRY_FILE="/etc/etherverse/registry.json"
SERVICE="etherverse-gateway.service"

echo "[⚙️] Scanning for latest agents_manifest.json..."
FOUND_MANIFESTS=($(find /home/etherverse -type f -name "agents_manifest.json"))

if [ ${#FOUND_MANIFESTS[@]} -eq 0 ]; then
  echo "[❌] No agents_manifest.json found under /home/etherverse" | tee -a "$TMP_LOG"
  exit 1
fi

# Choose the newest or largest file
LATEST_MANIFEST=$(ls -t "${FOUND_MANIFESTS[@]}" 2>/dev/null | head -n 1)
if [ -z "$LATEST_MANIFEST" ]; then
  LATEST_MANIFEST="${FOUND_MANIFESTS[0]}"
fi

echo "[📄] Using manifest: $LATEST_MANIFEST"
mkdir -p "$(dirname "$REGISTRY_FILE")"

# Verify jq installed
if ! command -v jq &>/dev/null; then
  echo "[📦] Installing jq..."
  sudo apt-get update -y && sudo apt-get install -y jq
fi

echo "[🧩] Building registry from $LATEST_MANIFEST ..."
jq -r '.agents[] | "\(.name):\(.port)"' "$LATEST_MANIFEST" 2>/dev/null | while IFS=: read -r NAME PORT; do
  [ -z "$NAME" ] && continue
  if ss -tulpn 2>/dev/null | grep -q ":$PORT "; then
    STATUS="online"
  else
    STATUS="offline"
  fi
  echo "{\"name\":\"$NAME\",\"port\":$PORT,\"status\":\"$STATUS\",\"last_seen\":\"$(date -u +%FT%TZ)\"}"
done | jq -s '.' > "$REGISTRY_FILE"

chmod 640 "$REGISTRY_FILE"
echo "[✅] Registry updated → $REGISTRY_FILE"
sudo systemctl restart "$SERVICE"
echo "[🚀] Gateway restarted @ $(date -u)"

