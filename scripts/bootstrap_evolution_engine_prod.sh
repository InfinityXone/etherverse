#!/usr/bin/env bash
set -euo pipefail

BASE="$HOME/etherverse/evolution_engine"
MODULES_DIR="$BASE/modules"
SCRIPTS_DIR="$BASE/scripts"
CONFIG_DIR="$BASE/config"
REPORTS_DIR="$BASE/reports"
DATA_DIR="$BASE/data"
STATE_DB="$DATA_DIR/state.sqlite"
CONFIG_FILE="$CONFIG_DIR/engine_user_info.cfg"
MASTER_SCRIPT="$SCRIPTS_DIR/run_engine.sh"
TIMER_FILE="/etc/systemd/system/evolution_engine.timer"
SERVICE_FILE="/etc/systemd/system/evolution_engine.service"

echo "[+] Bootstrap Evolution Engine – production setup (repo: ~/etherverse)"

# Create directory structure
mkdir -p "$MODULES_DIR" "$SCRIPTS_DIR" "$CONFIG_DIR" "$REPORTS_DIR" "$DATA_DIR"

# Create config placeholder if not present
if [[ ! -f "$CONFIG_FILE" ]]; then
  cat > "$CONFIG_FILE" << 'EOF'
# Etherverse Evolution Engine User Info
# alert_email="your-email@domain.com"
# git_update_repo="https://github.com/your-org/repos.git"
# threshold_optimum=90
# threshold_caution=70
# threshold_critical=50
EOF
  echo "[+] Created config file template at $CONFIG_FILE"
fi

# Create modules
cat > "$MODULES_DIR/diagnostics.py" << 'EOF'
#!/usr/bin/env python3
import subprocess, json, sqlite3, os, time

STATE_DB = os.path.expanduser("$STATE_DB")

def check_service(svc):
    try:
        out = subprocess.check_output(["systemctl","is-active",svc], text=True).strip()
    except Exception:
        out = "unknown"
    return out

def main():
    services = ["etherverse-daemon.service","etherverse-auto-update.service"]
    results = {}
    for s in services:
        results[s] = check_service(s)
    print("Diagnostics:", json.dumps(results))
    conn = sqlite3.connect(STATE_DB)
    cur = conn.cursor()
    cur.execute("CREATE TABLE IF NOT EXISTS diagnostics(ts INTEGER, service TEXT, status TEXT)")
    ts = int(time.time())
    for svc, status in results.items():
        cur.execute("INSERT INTO diagnostics(ts, service, status) VALUES(?,?,?)", (ts, svc, status))
    conn.commit()
    conn.close()

if __name__ == "__main__":
    main()
EOF

cat > "$MODULES_DIR/checklist.py" << 'EOF'
#!/usr/bin/env python3
import sqlite3, os, time

STATE_DB = os.path.expanduser("$STATE_DB")

def rate_system():
    conn = sqlite3.connect(STATE_DB)
    cur = conn.cursor()
    cur.execute("CREATE TABLE IF NOT EXISTS diagnostics(ts INTEGER, service TEXT, status TEXT)")
    rows = cur.execute("SELECT status FROM diagnostics ORDER BY ts DESC LIMIT 10").fetchall()
    conn.close()
    score = 100
    for (status,) in rows:
        if status != "active":
            score -= 5
    return max(score,0)

def main():
    score = rate_system()
    broken = []
    if score < 50:
        broken.append("Critical services down or unstable.")
    print(f"Checklist: score={score}")
    if broken:
        print("Broken items:")
        for b in broken:
            print(" -", b)

if __name__ == "__main__":
    main()
EOF

cat > "$MODULES_DIR/recommendation.py" << 'EOF'
#!/usr/bin/env python3
import os, subprocess

def main():
    print("Recommendations:")
    status = subprocess.run(["systemctl","is-active","etherverse-auto-update.service"], capture_output=True, text=True).stdout.strip()
    if status != "active":
        print(" - Repair or enable etherverse-auto-update.service")
    else:
        print(" - System update service active; no action needed.")
if __name__ == "__main__":
    main()
EOF

cat > "$MODULES_DIR/auto_heal.py" << 'EOF'
#!/usr/bin/env python3
import subprocess, time

def restart_service(svc):
    try:
        subprocess.run(["sudo","systemctl","restart",svc], check=True)
        return f"Restarted {svc}"
    except Exception as e:
        return f"Failed to restart {svc}: {e}"

def main():
    actions = []
    status = subprocess.run(["systemctl","is-active","etherverse-auto-update.service"], capture_output=True, text=True).stdout.strip()
    if status != "active":
        actions.append(restart_service("etherverse-auto-update.service"))
    print("Auto-heal actions:")
    for a in actions:
        print(" -", a)

if __name__ == "__main__":
    main()
EOF

# Create master run script
cat > "$MASTER_SCRIPT" << EOF
#!/usr/bin/env bash
set -euo pipefail
echo "=== Evolution Engine Run Start: \$(date) ==="
python3 "$MODULES_DIR/diagnostics.py"
python3 "$MODULES_DIR/checklist.py"
python3 "$MODULES_DIR/recommendation.py"
python3 "$MODULES_DIR/auto_heal.py"
echo "=== Evolution Engine Run Complete: \$(date) ==="
EOF

chmod +x "$MODULES_DIR/"*.py "$MASTER_SCRIPT"
echo "[+] Created master run script at $MASTER_SCRIPT"

# “nano button” prompt:
echo
echo "Press ENTER to open ~/etherverse/evolution_engine/scripts/run_engine.sh in nano for review..."
read -r _
nano "$MASTER_SCRIPT"

# Create systemd service & timer
cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Etherverse Evolution Engine Service

[Service]
Type=oneshot
User=$USER
WorkingDirectory=$BASE
ExecStart=$MASTER_SCRIPT
EOF

cat > "$TIMER_FILE" << EOF
[Unit]
Description=Run Etherverse Evolution Engine every hour

[Timer]
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now evolution_engine.timer

echo "[+] Installed systemd timer for automatic runs"

# Smoke test
echo "[+] Running smoke test"
bash "$MASTER_SCRIPT"
echo "[+] Smoke test complete – check logs/console for output"

echo "[+] Bootstrap complete. Module created at: $BASE"
echo "[+] Reports folder: $REPORTS_DIR"
echo "[+] Data state DB: $STATE_DB"
