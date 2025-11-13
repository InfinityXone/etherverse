#!/usr/bin/env bash
# =========================================================
# 🔍 Etherverse Memory System Scanner
# =========================================================
# Scans ~/etherverse for all memory-related components:
# - memory / memo / reflection / chroma / sqlite / docs / logs
# =========================================================

ROOT="$HOME/etherverse"
LOG="$ROOT/logs/memory_scan_$(date +%Y%m%d_%H%M).log"
echo "[🧠] Etherverse Memory System Scan — $(date)" | tee "$LOG"
echo "Root: $ROOT" | tee -a "$LOG"
echo "--------------------------------------------------------" | tee -a "$LOG"

# === 1️⃣ Directories likely to contain memory structures ===
echo "[📁] Listing candidate directories..." | tee -a "$LOG"
find "$ROOT" -type d \( -iname "*memory*" -o -iname "*memo*" -o -iname "*reflection*" -o -iname "*chroma*" -o -iname "*sqlite*" -o -iname "*log*" -o -iname "*doc*" \) 2>/dev/null | tee -a "$LOG"

echo "--------------------------------------------------------" | tee -a "$LOG"
# === 2️⃣ Key files (databases, logs, notebooks, docs) ===
echo "[📄] Listing candidate files..." | tee -a "$LOG"
find "$ROOT" -type f \( \
  -iname "*memory*" -o \
  -iname "*memo*" -o \
  -iname "*reflection*" -o \
  -iname "*chroma*" -o \
  -iname "*.db" -o \
  -iname "*.sqlite" -o \
  -iname "*.json" -o \
  -iname "*.md" -o \
  -iname "*.log" \
\) ! -path "*/venv/*" 2>/dev/null | tee -a "$LOG"

echo "--------------------------------------------------------" | tee -a "$LOG"
# === 3️⃣ Database quick summary ===
echo "[🗄️] Checking for active SQLite databases..." | tee -a "$LOG"
find "$ROOT" -type f -name "*.db" 2>/dev/null | while read -r DB; do
    echo "[📘] Found DB: $DB" | tee -a "$LOG"
    sqlite3 "$DB" ".tables" 2>/dev/null | sed 's/^/   └─ /' | tee -a "$LOG"
done

echo "--------------------------------------------------------" | tee -a "$LOG"
# === 4️⃣ Chroma / Vector stores ===
echo "[💠] Searching for Chroma vector stores..." | tee -a "$LOG"
find "$ROOT" -type d -name ".chroma" -o -name "chroma" 2>/dev/null | tee -a "$LOG"

echo "--------------------------------------------------------" | tee -a "$LOG"
# === 5️⃣ Summary counts ===
DIRS=$(find "$ROOT" -type d \( -iname "*memory*" -o -iname "*memo*" -o -iname "*reflection*" -o -iname "*chroma*" -o -iname "*sqlite*" -o -iname "*log*" -o -iname "*doc*" \) 2>/dev/null | wc -l)
FILES=$(find "$ROOT" -type f \( -iname "*memory*" -o -iname "*memo*" -o -iname "*reflection*" -o -iname "*chroma*" -o -iname "*.db" -o -iname "*.sqlite" -o -iname "*.json" -o -iname "*.md" -o -iname "*.log" \) 2>/dev/null | wc -l)

echo "[✅] Scan complete: $DIRS directories, $FILES files found." | tee -a "$LOG"
echo "[🧾] Log saved to: $LOG"
