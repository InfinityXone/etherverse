#!/usr/bin/env bash
# ==========================================================
#  Etherverse Production Bootstrap
#  Creates /etc/etherverse configuration + service scaffolding
# ==========================================================

set -e

echo "[🚀] Bootstrapping Etherverse production environment..."

# --- 1. Create config directories ---------------------------------------------
sudo mkdir -p /etc/etherverse
sudo chown -R etherverse:etherverse /etc/etherverse
sudo chmod 750 /etc/etherverse

# --- 2. Generate base configuration ------------------------------------------
CONFIG=/etc/etherverse/config.env
SECRETS=/etc/etherverse/secrets.env
COMBINED=/etc/etherverse/gateway.env

if [ ! -f "$CONFIG" ]; then
sudo tee "$CONFIG" >/dev/null <<'EOF'
# ===== Etherverse Production Config =====
ETHERVERSE_ENV=production
ETHERVERSE_PORT=8080
ETHERVERSE_BASE=/home/etherverse/etherverse
OLLAMA_HOST=http://127.0.0.1:11434
EOF
echo "[🧩] Created $CONFIG"
fi

if [ ! -f "$SECRETS" ]; then
NEWKEY=$(python3 -c "import secrets; print('ETHERKEY_prod_' + secrets.token_hex(16))")
sudo tee "$SECRETS" >/dev/null <<EOF
# ===== Etherverse Secrets =====
MEMORY_GATEWAY_TOKEN=$NEWKEY
SUPABASE_SERVICE_ROLE_KEY=
OPENAI_API_KEY=
GROQ_API_KEY=
EOF
sudo chmod 600 "$SECRETS"
echo "[🔒] Created $SECRETS with secure permissions."
fi

# --- 3. Combine into single file for systemd ---------------------------------
sudo bash -c "cat $CONFIG $SECRETS > $COMBINED"
sudo chmod 640 "$COMBINED"
echo "[⚙️] Combined config saved to $COMBINED"

# --- 4. Create / Update systemd service --------------------------------------
SERVICE=/etc/systemd/system/etherverse-gateway.service

sudo tee "$SERVICE" >/dev/null <<'EOF'
[Unit]
Description=Etherverse Gateway + QuantumMind (Production)
After=network.target

[Service]
User=etherverse
WorkingDirectory=/home/etherverse/etherverse
EnvironmentFile=/etc/etherverse/gateway.env
ExecStart=/home/etherverse/etherverse/venv/bin/python etherverse_gateway_init.py
Restart=on-failure
RestartSec=10
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now etherverse-gateway.service
echo "[✅] Etherverse Gateway service installed and enabled."

# --- 5. Display API key for testing ------------------------------------------
API_KEY=$(grep MEMORY_GATEWAY_TOKEN "$SECRETS" | cut -d= -f2)
echo "[🔑] Use this API key for local requests:"
echo "     curl -H \"X-Api-Key: $API_KEY\" http://127.0.0.1:8080/"
echo "[🎯] Bootstrap complete!"
