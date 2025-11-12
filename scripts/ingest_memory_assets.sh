#!/bin/bash
# ============================================================
# 🧬 Etherverse Memory Asset Ingestor — Fixed
# Stores discovered memory-related files into Hive memory DB
# ============================================================

ROOT="$HOME/etherverse"
DB="$ROOT/core/shared_memory/hive_memory.db"
LOGDIR="$ROOT/logs"
REPORT=$(ls -t "$LOGDIR"/memory_assets_report_*.txt | head -n1)

echo "[🧬] Ingesting memory asset report into Hive shared memory..."

# --- Ensure DB path exists
mkdir -p "$(dirname "$DB")"
touch "$DB"

# --- Activate venv
source "$ROOT/venv/bin/activate"

python3 - <<'PYCODE'
import sqlite3, os, time

ROOT=os.path.expanduser("~/etherverse")
DB=os.path.join(ROOT,"core/shared_memory/hive_memory.db")
LOGDIR=os.path.join(ROOT,"logs")
REPORT=max(
    [os.path.join(LOGDIR,f) for f in os.listdir(LOGDIR) if f.startswith("memory_assets_report_")],
    key=os.path.getctime
)

print(f"[🧩] Using report: {REPORT}")
os.makedirs(os.path.dirname(DB), exist_ok=True)

conn=sqlite3.connect(DB)
conn.execute("""
CREATE TABLE IF NOT EXISTS asset_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  path TEXT,
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
)
""")

count=0
with open(REPORT) as f:
    for line in f:
        l=line.strip().lower()
        if any(k in l for k in ["memory","memo","reflect","journal","wisdom",".db",".sqlite"]):
            conn.execute("INSERT INTO asset_log(path) VALUES (?)", (line.strip(),))
            count+=1
conn.commit()
conn.close()
print(f"[✅] Ingested {count} memory-related paths into Hive memory DB")
PYCODE
