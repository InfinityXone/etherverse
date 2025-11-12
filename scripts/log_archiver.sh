#!/usr/bin/env bash
# =============================================
# Etherverse Log Archiver – daily maintenance
# =============================================

LOG_DIR="$HOME/etherverse/logs"
ARCHIVE_DIR="$LOG_DIR/archive"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ARCHIVE_FILE="$ARCHIVE_DIR/logs_$TIMESTAMP.tar.gz"

mkdir -p "$ARCHIVE_DIR"

echo "[🌀] Compressing and archiving current logs..."
tar -czf "$ARCHIVE_FILE" -C "$LOG_DIR" ./*.log 2>/dev/null

echo "[🧹] Clearing active log files..."
find "$LOG_DIR" -maxdepth 1 -type f -name "*.log" -exec truncate -s 0 {} \;

echo "[✅] Logs archived to: $ARCHIVE_FILE"
echo "[🕰] Next run scheduled: daily via systemd timer (if enabled)."
