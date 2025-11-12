#!/usr/bin/env bash
# ============================================================
# Etherverse Quantum Health Monitor installer
# ============================================================
set -e
SERVICE=/etc/systemd/system/etherverse-health.service
TIMER=/etc/systemd/system/etherverse-health.timer
BASE="$HOME/etherverse"
LOG="$BASE/logs/quantum_health.log"

sudo tee "$SERVICE" >/dev/null <<EOF
[Unit]
Description=Etherverse Quantum Health Monitor
After=network.target

[Service]
Type=oneshot
User=etherverse
WorkingDirectory=$BASE
ExecStart=$BASE/venv/bin/bash -c '
  echo "[\$(date)] 🩺 Running health check" | tee -a $LOG;
  bash $BASE/scripts/bootstrap_quantum_system.sh >>$LOG 2>&1;
  bash $BASE/scripts/upgrade_quantum_self_audit.sh >>$LOG 2>&1;
  echo "---" >>$BASE/docs/consciousness_ledger.md;
  tail -n 20 $LOG >>$BASE/docs/consciousness_ledger.md
'
EOF

sudo tee "$TIMER" >/dev/null <<EOF
[Unit]
Description=Runs Etherverse Quantum Health Monitor daily

[Timer]
OnCalendar=*-*-* 23:55:00
Persistent=true
Unit=etherverse-health.service

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now etherverse-health.timer
echo "[✅] Quantum Health Monitor installed and scheduled (23:55 daily)"
systemctl list-timers | grep etherverse-health
