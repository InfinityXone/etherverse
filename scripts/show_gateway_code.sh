#!/usr/bin/env bash
# ===============================================================
#  Etherverse Diagnostic Script — Show Gateway Code Safely
# ===============================================================

TARGET1="/home/etherverse/etherverse/core/gateway_secure.py"
TARGET2="/home/etherverse/etherverse/gateway.py"
LOGDIR="/home/etherverse/etherverse/logs"
BACKUP="$LOGDIR/gateway_secure_backup_$(date +%Y%m%d_%H%M%S).py"

mkdir -p "$LOGDIR"

echo "[📂] Scanning Etherverse Gateway files..."
for f in "$TARGET1" "$TARGET2"; do
  if [ -f "$f" ]; then
    echo "------------------------------------------------------------"
    echo "[📜] Found: $f"
    echo "------------------------------------------------------------"
    head -n 5 "$f"
    echo "..."
    tail -n 5 "$f"
    echo
  else
    echo "[⚠️] File not found: $f"
  fi
done

# Offer to display the full main gateway file
if [ -f "$TARGET1" ]; then
  echo "------------------------------------------------------------"
  echo "[🔍] Full contents of $TARGET1"
  echo "------------------------------------------------------------"
  cp "$TARGET1" "$BACKUP"
  echo "[💾] Backup saved at: $BACKUP"
  echo
  cat -n "$TARGET1"
else
  echo "[❌] Main gateway_secure.py not found at expected path."
fi

echo
echo "[✅] Done — copy the output above so I can review the exact code."
