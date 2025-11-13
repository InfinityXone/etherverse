#!/usr/bin/env bash
# =========================================================
# ☁️ Etherverse Drive Sync Script
# =========================================================
# Mirrors ~/etherverse → Google Drive (remote: gdrive)
# Excludes logs, venv, and cache directories
# =========================================================

SRC="$HOME/etherverse"
DEST="gdrive:etherverse-backup"
LOG="$HOME/etherverse/logs/drive_sync.log"

echo "[☁️] Starting Etherverse → Google Drive sync @ $(date)" | tee -a "$LOG"

rclone sync "$SRC" "$DEST" \
  --exclude "venv/**" \
  --exclude "logs/**" \
  --include "memory_core/**" \
  --include "memory_core/**" \
  --exclude "*.pyc" \
  --exclude "__pycache__/**" \
  --progress \
  --log-file "$LOG"
  --exclude "tmp/**" \

if [ $? -eq 0 ]; then
  echo "[✅] Sync completed successfully @ $(date)" | tee -a "$LOG"
else
  echo "[❌] Sync encountered errors — check $LOG" | tee -a "$LOG"
fi
