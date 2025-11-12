#!/bin/bash
# ============================================================
# 🧬 Etherverse Quantum System Snapshot & Auto-Sync
# Logs current daemon, timers, git, and system metrics
# ============================================================

BASE_DIR="$HOME/etherverse"
REPORT_DIR="$BASE_DIR/docs"
LOG_DIR="$BASE_DIR/logs"
REPORT_FILE="$REPORT_DIR/system_snapshot_$(date '+%Y%m%d_%H%M').md"

mkdir -p "$REPORT_DIR" "$LOG_DIR"

{
  echo "# 🧬 Etherverse Quantum System Snapshot — $(date)"
  echo
  echo "## 🔹 Core Services"
  echo "### etherverse-daemon.service"
  systemctl is-active etherverse-daemon.service || echo "inactive"
  echo
  echo "### etherverse-auto-update.timer"
  systemctl is-active etherverse-auto-update.timer || echo "inactive"
  echo

  echo "## 🔹 Git Repository Status"
  git -C "$BASE_DIR" status
  echo

  echo "## 🔹 Recent Daemon Logs"
  tail -n 30 "$LOG_DIR/daemon.log" 2>/dev/null || echo "No daemon log found."
  echo

  echo "## 🔹 Memory & Disk"
  free -h
  df -h "$BASE_DIR"
  echo
} > "$REPORT_FILE"

# Commit and push snapshot
cd "$BASE_DIR"
if [ -f .git/index.lock ]; then rm -f .git/index.lock; fi
git add "$REPORT_FILE"
git commit -m "🧩 Auto Snapshot: $(date '+%Y-%m-%d %H:%M:%S')" >/dev/null 2>&1 || true
git push origin main >/dev/null 2>&1 || echo "[⚠] Git push skipped (offline)"

echo "[✅] Snapshot written to: $REPORT_FILE"
