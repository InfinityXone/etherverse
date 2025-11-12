#!/usr/bin/env bash
#
# bootstrap_evolution_engine_full_v2.sh — improved scaffold for Evolution Engine
#

set -e  # exit on first error
echo "[+] Starting Evolution Engine bootstrap"

BASE="$HOME/etherverse"
MODULE="$BASE/evolution_engine"
SCRIPTS_ROOT="$BASE/scripts"
ENGINE_SCRIPTS="$MODULE/scripts"

echo "[+] Creating folder structure"
mkdir -p "$MODULE"/{config,data/metrics,data/history,data/state,sandbox/updates_pending,modules,reports/past,service,docs}
mkdir -p "$ENGINE_SCRIPTS"

echo "[+] Writing configuration file"
cat > "$MODULE/config/engine_config.yaml" << 'EOF'
# Evolution Engine Configuration
scan_interval: 30m
innovation_window: weekly
score_thresholds:
  optimum: 90
  caution: 70
  critical: 50
auto_heal_enabled: true
sandbox_mode: true
update_repo: "https://github.com/your-org/evolution-engine-updates.git"
rollback_limit: 5
alert_channels:
  email: you@domain.com
  slack_webhook: "https://hooks.slack.com/…"
EOF

echo "[+] Writing diagnostics module"
cat > "$MODULE/modules/diagnostics.py" << EOF
#!/usr/bin/env python3
import sqlite3, time, os, subprocess

DB_PATH = os.path.expanduser("${MODULE}/data/state.sqlite")

def init_db():
    conn = sqlite3.connect(DB_PATH)
    conn.execute("CREATE TABLE IF NOT EXISTS metrics(ts INTEGER, metric TEXT, value TEXT)")
    conn.commit()
    conn.close()

def record(metric, value):
    conn = sqlite3.connect(DB_PATH)
    conn.execute("INSERT INTO metrics(ts, metric, value) VALUES (?, ?, ?)",
                 (int(time.time()), metric, str(value)))
    conn.commit()
    conn.close()

def check_services():
    svcs = ["etherverse-daemon.service","etherverse-auto-update.service"]
    results = {}
    for s in svcs:
        try:
            status = subprocess.check_output(["systemctl","is-active",s], text=True).strip()
        except Exception:
            status = "unknown"
        results[s] = status
    return results

if __name__ == "__main__":
    init_db()
    res = check_services()
    for svc, st in res.items():
        record(svc, st)
    print("Diagnostics module ran successfully:", res)
EOF

echo "[+] Writing run script"
cat > "$ENGINE_SCRIPTS/run_engine.sh" << EOF
#!/usr/bin/env bash
echo "=== Evolution Engine Smoke Test Start ==="
python3 "${MODULE}/modules/diagnostics.py"
_EXIT=\$?
if [ \$_EXIT -ne 0 ]; then
  echo "[!] Diagnostics module failed with exit code \$_EXIT"
  exit \$_EXIT
fi
echo "=== Smoke Test Completed at $(date) ==="
EOF

echo "[+] Writing systemd service & timer files"
cat > "$MODULE/service/evolution_engine.service" << EOF
[Unit]
Description=Evolution Engine – Monitoring & Self-Evolution
After=network.target

[Service]
Type=oneshot
User=$(whoami)
ExecStart=${MODULE}/scripts/run_engine.sh

[Install]
WantedBy=multi-user.target
EOF

cat > "$MODULE/service/evolution_engine.timer" << EOF
[Unit]
Description=Run Evolution Engine diagnostics hourly

[Timer]
OnBootSec=5min
OnUnitActiveSec=1h
Persistent=true

[Install]
WantedBy=timers.target
EOF

echo "[+] Setting execute permissions"
chmod +x "$ENGINE_SCRIPTS/run_engine.sh"
chmod +x "$MODULE/modules/diagnostics.py"

echo "[+] Opening run script for review"
nano "$ENGINE_SCRIPTS/run_engine.sh"

echo "[+] Installing systemd units"
sudo cp "$MODULE/service/evolution_engine.service" /etc/systemd/system/
sudo cp "$MODULE/service/evolution_engine.timer" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable evolution_engine.timer
sudo systemctl start evolution_engine.timer

echo "[+] Running initial smoke test"
bash "$ENGINE_SCRIPTS/run_engine.sh"

echo "[+] Bootstrap complete. Module created at: $MODULE"
echo "[+] Report folder: $MODULE/reports"
echo "[+] State DB file: $MODULE/data/state.sqlite"
