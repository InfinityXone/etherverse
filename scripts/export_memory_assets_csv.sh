#!/bin/bash
# ============================================================
# 📊 Etherverse Memory Assets CSV Exporter
# ============================================================
ROOT="$HOME/etherverse"
LOGDIR="$ROOT/logs"
REPORT=$(ls -t "$LOGDIR"/memory_assets_report_*.txt | head -n1)
OUT="$LOGDIR/memory_assets_export_$(date +%Y%m%d_%H%M%S).csv"

echo "timestamp,path,type" > "$OUT"

grep -Ei "memory|memo|reflect|journal|wisdom|\.db|\.sqlite" "$REPORT" \
  | while read -r line; do
      TYPE="file"
      [[ "$line" =~ "/" ]] || TYPE="text"
      echo "$(date +'%Y-%m-%d %H:%M:%S'),\"$line\",\"$TYPE\"" >> "$OUT"
    done

echo "[✅] CSV export complete."
echo "[📁] File saved to: $OUT"
