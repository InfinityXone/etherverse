#!/usr/bin/env bash
set -euo pipefail

TIMESTAMP=$(date +"%Y%m%d_%H%M")
LOGDIR="$HOME/etherverse/logs"
OUTFILE="$LOGDIR/full_memory_snapshot_${TIMESTAMP}.log"

mkdir -p "$LOGDIR"

echo "====================================================" | tee "$OUTFILE"
echo "        E T H E R V E R S E   M E M O R Y " | tee -a "$OUTFILE"
echo "              F U L L   S N A P S H O T" | tee -a "$OUTFILE"
echo "====================================================" | tee -a "$OUTFILE"
echo "Timestamp: $TIMESTAMP" | tee -a "$OUTFILE"
echo "" | tee -a "$OUTFILE"

ROOT="$HOME/etherverse"

#################################################################
# SECTION 1 — FOLDER STRUCTURE
#################################################################
echo "===[ 1. FOLDER STRUCTURE ]====================================" | tee -a "$OUTFILE"

find "$ROOT" -maxdepth 5 -type d \
  | grep -v "__pycache__" \
  | grep -v "node_modules" \
  | grep -v "tmp" \
  | grep -v ".git" \
  | grep -v "venv" \
  | sort | tee -a "$OUTFILE"

echo "" | tee -a "$OUTFILE"

#################################################################
# SECTION 2 — MEMORY SYSTEM FILES
#################################################################
echo "===[ 2. MEMORY SYSTEM FILES ]=================================" | tee -a "$OUTFILE"

find "$ROOT" \
  -type f \
  \( -iname "*.json" -o -iname "*.sqlite*" -o -iname "*.db" -o -iname "*.log" -o -iname "*.txt" \) \
  | grep -Ei "memory|brain|reflect|dream|semantic|graph|vector|chroma|faiss" \
  | sort | tee -a "$OUTFILE"

echo "" | tee -a "$OUTFILE"

#################################################################
# SECTION 3 — CHROMA DB STATUS
#################################################################
echo "===[ 3. CHROMA VECTOR DB STATUS ]=============================" | tee -a "$OUTFILE"

if [ -d "$ROOT/memory/chroma" ]; then
  du -sh "$ROOT/memory/chroma" | tee -a "$OUTFILE"
  ls -R "$ROOT/memory/chroma" | tee -a "$OUTFILE"
else
  echo "[No Chroma directory found]" | tee -a "$OUTFILE"
fi

echo "" | tee -a "$OUTFILE"

#################################################################
# SECTION 4 — SQLITE / DB FILES
#################################################################
echo "===[ 4. SQLITE / DATABASE FILES ]==============================" | tee -a "$OUTFILE"

find "$ROOT" -type f -iname "*.sqlite*" | tee -a "$OUTFILE"
find "$ROOT" -type f -iname "*.db"       | tee -a "$OUTFILE"

echo "" | tee -a "$OUTFILE"

#################################################################
# SECTION 5 — LOGS & REFLECTION SYSTEM
#################################################################
echo "===[ 5. LOGS, REFLECTION, DREAM FILES ]========================" | tee -a "$OUTFILE"

find "$ROOT/logs" -type f \
  | grep -Ei "reflect|dream|heartbeat|watchdog|memory|gateway" \
  | tee -a "$OUTFILE"

echo "" | tee -a "$OUTFILE"

#################################################################
# SECTION 6 — PYTHON ENVIRONMENT (VENV)
#################################################################
echo "===[ 6. PYTHON ENVIRONMENT PACKAGES ]==========================" | tee -a "$OUTFILE"

if [ -x "$ROOT/etherverse/venv/bin/pip" ]; then
  "$ROOT/etherverse/venv/bin/pip" freeze | tee -a "$OUTFILE"
else
  echo "[Venv pip not found]" | tee -a "$OUTFILE"
fi

echo "" | tee -a "$OUTFILE"

#################################################################
# SECTION 7 — SYSTEMD SERVICES
#################################################################
echo "===[ 7. SYSTEMD SERVICES ]====================================" | tee -a "$OUTFILE"

systemctl list-units --type=service --all \
  | grep -Ei "etherverse|memory|guardian|daemon|gateway|reflect" \
  | tee -a "$OUTFILE"

echo "" | tee -a "$OUTFILE"

#################################################################
# SECTION 8 — ACTIVE PROCESSES
#################################################################
echo "===[ 8. ACTIVE PROCESSES ]====================================" | tee -a "$OUTFILE"

ps aux | grep -Ei "etherverse|memory|daemon|gateway" | grep -v grep | tee -a "$OUTFILE"

echo "" | tee -a "$OUTFILE"

#################################################################
# SECTION 9 — RSYNC / DRIVE SYNC STATUS
#################################################################
echo "===[ 9. DRIVE & RSYNC SYNCING ]===============================" | tee -a "$OUTFILE"

ls "$ROOT/scripts" | grep -Ei "sync" | tee -a "$OUTFILE"

echo "" | tee -a "$OUTFILE"

#################################################################
# SECTION 10 — COMPLETE FILE SNAPSHOT
#################################################################
echo "===[ 10. COMPLETE FILE SNAPSHOT (cleaned) ]====================" | tee -a "$OUTFILE"

find "$ROOT" -type f \
  | grep -v "__pycache__" \
  | grep -v "node_modules" \
  | grep -v ".git" \
  | grep -v "tmp" \
  | sort | tee -a "$OUTFILE"

echo "" | tee -a "$OUTFILE"

echo "====================================================" | tee -a "$OUTFILE"
echo "FULL SNAPSHOT COMPLETE → $OUTFILE" | tee -a "$OUTFILE"
echo "====================================================" | tee -a "$OUTFILE"
