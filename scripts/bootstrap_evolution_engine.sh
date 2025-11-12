#!/usr/bin/env bash
#
# bootstrap_evolution_engine.sh — scaffold “Evolution Engine” module under ~/etherverse
# Generates module, service files, scripts, and runs initial test.
#

BASE="$HOME/etherverse"
MODULE_DIR="$BASE/evolution_engine"
SCRIPTS_DIR="$BASE/scripts"
ENGINE_SCRIPTS_DIR="$MODULE_DIR/scripts"

# 1. Create module folder structure
mkdir -p "$MODULE_DIR"/{config,data/metrics,data/history,sandbox/updates_pending,modules,reports/past,service,docs}
mkdir -p "$ENGINE_SCRIPTS_DIR"

# 2. Create configuration file (industry standard naming)
cat > "$MODULE_DIR/config/engine_config.yaml" << 'EOF'
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

# 3. Create key modules
cat > "$MODULE_DIR/modules/diagnostics.py" << 'EOF'
#!/usr/bin/env python3
import sqlite3, time, os, subprocess

DB_PATH = os.path.expanduser("$MODULE_DIR/data/state.sqlite")

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

# 4. Create run script (master execution)
cat > "$ENGINE_SCRIPTS_DIR/run_engine.sh" << 'EOF'
#!/usr/bin/env bash
echo "=== Evolution Engine Smoke Test Start ==="
python3 "$MODULE_DIR/modules/diagnostics.py"
echo "=== Smoke Test Completed at $(date) ==="
EOF

# 5. Create service and timer files
cat > "$MODULE_DIR/service/evolution_engine.service" << 'EOF'
[Unit]
Description=Evolution Engine – Monitoring & Self-Evolution
After=network.target

[Service]
Type=oneshot
User=$(whoami)
ExecStart=$MODULE_DIR/scripts/run_engine.sh

[Install]
WantedBy=multi-user.target
EOF

cat > "$MODULE_DIR/service/evolution_engine.timer" << 'EOF'
[Unit]
Description=Run Evolution Engine diagnostics hourly

[Timer]
OnBootSec=5min
OnUnitActiveSec=1h
Persistent=true

[Install]
WantedBy=timers.target
EOF

# 6. Make scripts executable
chmod +x "$ENGINE_SCRIPTS_DIR/run_engine.sh"
chmod +x "$MODULE_DIR/modules/diagnostics.py"

# 7. Open run script in nano for your review
nano "$ENGINE_SCRIPTS_DIR/run_engine.sh"

# 8. Deploy systemd service & timer
sudo cp "$MODULE_DIR/service/evolution_engine.service" /etc/systemd/system/
sudo cp "$MODULE_DIR/service/evolution_engine.timer" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable evolution_engine.timer
sudo systemctl start evolution_engine.timer

# 9. Perform initial smoke test
bash "$ENGINE_SCRIPTS_DIR/run_engine.sh"

echo "✅ Bootstrap complete. See report and data under: $MODULE_DIR"
