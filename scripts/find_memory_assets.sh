#!/bin/bash
# ============================================================
# 🔍 Etherverse Memory Intelligence Scanner
# Scans for all files and directories related to memory,
# memo, reflection, journaling, wisdom, or SQLite databases.
# ============================================================

ROOT="$HOME/etherverse"
REPORT="$ROOT/logs/memory_assets_report_$(date +%Y%m%d_%H%M%S).txt"

echo "[🧠] Starting Etherverse memory asset scan..."
mkdir -p "$ROOT/logs"

{
  echo "=============================================="
  echo "  ETHERVERSE MEMORY & REFLECTION SCAN REPORT  "
  echo "  Generated: $(date)"
  echo "  Root: $ROOT"
  echo "=============================================="
  echo ""

  echo "[📁] Searching for memory, memo, reflection, journaling, wisdom directories..."
  find "$ROOT" -type d \( \
    -iname "*memory*" -o -iname "*memo*" -o -iname "*reflect*" \
    -o -iname "*journal*" -o -iname "*wisdom*" \) 2>/dev/null

  echo ""
  echo "[📄] Searching for related files (txt, md, json, py, db, sqlite)..."
  find "$ROOT" -type f \( \
    -iname "*memory*" -o -iname "*memo*" -o -iname "*reflect*" \
    -o -iname "*journal*" -o -iname "*wisdom*" \
    -o -iname "*.sqlite" -o -iname "*.db" -o -iname "*.sql" \) 2>/dev/null

  echo ""
  echo "[💾] Listing SQLite and database files with size and modification date..."
  find "$ROOT" -type f \( -iname "*.sqlite" -o -iname "*.db" -o -iname "*.sql" \) \
    -exec ls -lh {} \; 2>/dev/null

  echo ""
  echo "[🧩] Searching for keywords within Python or log files..."
  grep -RinE "(memory|memo|reflect|journal|wisdom)" "$ROOT" \
    --include="*.py" --include="*.log" --include="*.txt" --include="*.md" 2>/dev/null | head -n 200

  echo ""
  echo "[🪶] Summary of discovered memory databases:"
  find "$ROOT" -type f -name "*.db" -exec sqlite3 {} "SELECT name FROM sqlite_master WHERE type='table';" \; 2>/dev/null | sort | uniq

  echo ""
  echo "=============================================="
  echo "Report complete — total disk usage summary:"
  du -sh "$ROOT"/* 2>/dev/null | sort -h
  echo "=============================================="
} > "$REPORT"

echo "[✅] Scan complete. Report saved to: $REPORT"
echo "[💡] To view results:"
echo "cat \"$REPORT\" | less"
