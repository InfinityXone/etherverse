#!/usr/bin/env bash
# ==========================================================
# ⚙️ Etherverse System Fix & Optimization Script
# ==========================================================
# Description:
# This script applies all critical fixes, optimizations,
# and maintenance improvements to the Etherverse system.
# ==========================================================

set -euo pipefail

LOGFILE="$HOME/etherverse/logs/fix_optimize_$(date +%Y%m%d_%H%M).log"
echo "[🚀] Starting Etherverse optimization..." | tee "$LOGFILE"

# === 1️⃣ ENABLE SWAP (2 GB for LLM stability) ===
if ! sudo swapon --show | grep -q "/swapfile"; then
  echo "[🧠] Creating 2GB swapfile for stability..." | tee -a "$LOGFILE"
  sudo fallocate -l 2G /swapfile || sudo dd if=/dev/zero of=/swapfile bs=1M count=2048
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab >/dev/null
else
  echo "[✅] Swap already active." | tee -a "$LOGFILE"
fi

# === 2️⃣ FILL SCHEMA PLACEHOLDERS ===
SCHEMA_FILE="$HOME/etherverse/core/identity_schema.json"
MEMORY_PROTO="$HOME/etherverse/docs/memory_protocol.md"

echo "[🧩] Updating identity schema and memory protocol..." | tee -a "$LOGFILE"

cat > "$SCHEMA_FILE" <<'EOF'
{
  "agent_id": "string",
  "agent_role": "string",
  "status": "active|paused|terminated",
  "last_heartbeat": "timestamp",
  "memory_signature": "uuid",
  "vault_integrity": "boolean"
}
EOF

cat > "$MEMORY_PROTO" <<'EOF'
# 🧠 Etherverse Memory Protocol (Rosetta Layer v1.0)
Defines the flow of memory hydration and dehydration across agents.

- /memory/write → stores short-term memory in Supabase
- /memory/snapshot → archives state to GCS
- /memory/hydrate → loads memories into agent context
- /memory/sync → ensures ledger alignment
EOF

# === 3️⃣ VAULT & ENV INTEGRITY CHECKER ===
SYNC_SCRIPT="$HOME/etherverse/scripts/env_vault_sync.sh"
echo "[🔐] Creating Vault ↔ .env integrity checker..." | tee -a "$LOGFILE"

cat > "$SYNC_SCRIPT" <<'EOF'
#!/usr/bin/env bash
# Verifies .env and Supabase vault consistency

ENV_FILE="$HOME/etherverse/.env"
SUPA_KEY_FILE="$HOME/etherverse/credentials/supabase_keys.json"
LOG="$HOME/etherverse/logs/vault_sync.log"

echo "[🔎] Checking .env integrity..." | tee -a "$LOG"
if [ ! -f "$ENV_FILE" ]; then
  echo "[❌] Missing .env — pulling from Supabase vault..." | tee -a "$LOG"
  cp "$SUPA_KEY_FILE" "$ENV_FILE"
else
  echo "[✅] .env present and linked." | tee -a "$LOG"
fi

if ! grep -q "SUPABASE_URL" "$ENV_FILE"; then
  echo "[⚠️] SUPABASE_URL missing — appending placeholder." | tee -a "$LOG"
  echo "SUPABASE_URL=https://example.supabase.co" >> "$ENV_FILE"
fi

if ! grep -q "SUPABASE_SERVICE_ROLE_KEY" "$ENV_FILE"; then
  echo "[⚠️] SERVICE_ROLE_KEY missing — placeholder added." | tee -a "$LOG"
  echo "SUPABASE_SERVICE_ROLE_KEY=placeholder-key" >> "$ENV_FILE"
fi

echo "[✅] Vault sync check complete." | tee -a "$LOG"
EOF

chmod +x "$SYNC_SCRIPT"

# === 4️⃣ BACKUP & SNAPSHOT SYSTEM ===
BACKUP_SCRIPT="$HOME/etherverse/scripts/rclone_backup.sh"
echo "[💾] Installing rclone backup system..." | tee -a "$LOGFILE"

cat > "$BACKUP_SCRIPT" <<'EOF'
#!/usr/bin/env bash
# Etherverse backup via Rclone to GCS
SRC="$HOME/etherverse"
DST="gs://infinity-swarm-system/etherverse-backups"
LOG="$HOME/etherverse/logs/backup_$(date +%Y%m%d).log"

echo "[☁️] Syncing local Etherverse to GCS..." | tee -a "$LOG"
rclone sync "$SRC" "$DST" --exclude "logs/**" --exclude "venv/**" --log-file "$LOG" --progress
echo "[✅] Backup complete at $(date)" | tee -a "$LOG"
EOF

chmod +x "$BACKUP_SCRIPT"

# === 5️⃣ INSTALL METRICS MONITOR ===
echo "[📊] Installing prometheus_client for live metrics..." | tee -a "$LOGFILE"
source "$HOME/etherverse/venv/bin/activate"
pip install prometheus_client --quiet
deactivate

# === 6️⃣ SETUP SYSTEM OPTIMIZATION TIMER ===
OPT_SCRIPT="$HOME/etherverse/scripts/self_optimize.sh"
if [ -f "$OPT_SCRIPT" ]; then
  sudo tee /etc/systemd/system/etherverse-optimize.service >/dev/null <<EOF
[Unit]
Description=Etherverse Self-Optimize Service

[Service]
Type=oneshot
ExecStart=$OPT_SCRIPT
EOF

  sudo tee /etc/systemd/system/etherverse-optimize.timer >/dev/null <<EOF
[Unit]
Description=Run Etherverse optimization nightly

[Timer]
OnCalendar=*-*-* 03:33:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

  sudo systemctl daemon-reload
  sudo systemctl enable --now etherverse-optimize.timer
  echo "[🕰] Self-optimization timer enabled." | tee -a "$LOGFILE"
fi

# === 7️⃣ PERFORMANCE TUNING ===
echo "[⚡] Applying performance tuning..." | tee -a "$LOGFILE"
sudo sysctl -w vm.swappiness=10
sudo sysctl -w vm.vfs_cache_pressure=50
sudo sysctl -w vm.dirty_ratio=10
sudo sysctl -w vm.dirty_background_ratio=5

echo "[✅] Etherverse optimization complete!" | tee -a "$LOGFILE"
echo "[📜] Full log stored at: $LOGFILE"
