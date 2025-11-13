#!/usr/bin/env bash
# ===============================================================
#  Etherverse Omni-Gateway Fine Tuning & Validation Script
# ===============================================================

set -e
PORT=8081
SERVICE=etherverse-gateway.service
CONFIG=/etc/etherverse/config.env
SECRETS=/etc/etherverse/secrets.env
COMBINED=/etc/etherverse/gateway.env

echo "[⚙️] Fine-tuning Etherverse Omni-Gateway configuration..."

# --- 1️⃣  Update configuration with correct port ----------------------------
if grep -q "^ETHERVERSE_PORT=" "$CONFIG"; then
    sudo sed -i "s/^ETHERVERSE_PORT=.*/ETHERVERSE_PORT=$PORT/" "$CONFIG"
else
    echo "ETHERVERSE_PORT=$PORT" | sudo tee -a "$CONFIG" >/dev/null
fi

echo "[🔧] Port locked to $PORT in $CONFIG"

# --- 2️⃣  Merge configuration and secrets -----------------------------------
sudo bash -c "cat $CONFIG $SECRETS > $COMBINED"
sudo chmod 640 "$COMBINED"
echo "[🔐] Refreshed combined gateway environment."

# --- 3️⃣  Update systemd service ExecStart -----------------------------------
sudo tee /etc/systemd/system/$SERVICE >/dev/null <<EOF
[Unit]
Description=Etherverse Omni-Gateway (Production)
After=network.target

[Service]
User=etherverse
WorkingDirectory=/home/etherverse/etherverse
EnvironmentFile=/etc/etherverse/gateway.env
ExecStart=/home/etherverse/etherverse/venv/bin/uvicorn core.gateway_secure:app --host 0.0.0.0 --port $PORT
Restart=on-failure
RestartSec=10
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl restart $SERVICE
echo "[✅] Service reloaded and running on port $PORT."

# --- 4️⃣  Create monitoring aliases -----------------------------------------
echo "[📡] Installing helpful shell aliases..."
ALIAS_FILE="$HOME/.bash_aliases"
{
echo "alias etherverse-health='curl -H \"X-Api-Key: \$(grep MEMORY_GATEWAY_TOKEN $SECRETS | cut -d= -f2)\" http://127.0.0.1:$PORT/'"
echo "alias etherverse-logs='sudo journalctl -fu $SERVICE'"
echo "alias etherverse-restart='sudo systemctl restart $SERVICE && sudo systemctl status $SERVICE'"
} >> "$ALIAS_FILE"

source "$ALIAS_FILE"
echo "[🧭] Aliases installed: etherverse-health, etherverse-logs, etherverse-restart"

# --- 5️⃣  Validation tests ---------------------------------------------------
API_KEY=$(grep MEMORY_GATEWAY_TOKEN "$SECRETS" | cut -d= -f2)
echo "[🔑] Using API key: $API_KEY"

echo "[🧪] Testing health endpoint..."
curl -s -H "X-Api-Key: $API_KEY" http://127.0.0.1:$PORT/ || echo "⚠️  Health check failed."

# --- 6️⃣  Optional: test /reflect endpoint if it exists ----------------------
echo "[🪞] Testing reflect endpoint (if available)..."
curl -s -X POST http://127.0.0.1:$PORT/reflect \
  -H "X-Api-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"prompt":"Reflect on current Etherverse gateway status."}' \
  || echo "⚠️  Reflect endpoint unavailable."

echo "[🎯] Fine-tuning completed successfully!"
