#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/etherverse"
MEM="$ROOT/memory_core"
mkdir -p "$MEM"/{data,chroma,logs,scripts}

echo "[1/5] Installing open-source dependencies..."
sudo apt install -y redis-server postgresql libpq-dev
source "$ROOT/venv/bin/activate"
pip install fastapi uvicorn chromadb redis psycopg2-binary langgraph

echo "[2/5] Initializing databases..."
sudo -u postgres psql -c "CREATE DATABASE etherverse_memory;" || true
sqlite3 "$MEM/data/hive_local.db" \
"CREATE TABLE IF NOT EXISTS memories(id INTEGER PRIMARY KEY,agent TEXT,event TEXT,content TEXT,created_at TEXT DEFAULT (datetime('now')));"

echo "[3/5] Creating gateway..."
cat > "$MEM/memory_gateway.py" <<'PY'
from fastapi import FastAPI
import sqlite3, datetime
app = FastAPI()

@app.post("/write")
def write(agent:str, event:str, content:str):
    conn = sqlite3.connect("memory_core/data/hive_local.db")
    conn.execute("INSERT INTO memories(agent,event,content,created_at) VALUES (?,?,?,?)",
                 (agent,event,content,datetime.datetime.utcnow().isoformat()))
    conn.commit(); conn.close()
    return {"status":"ok"}

@app.get("/query")
def query(agent:str):
    conn=sqlite3.connect("memory_core/data/hive_local.db")
    cur=conn.execute("SELECT event,content FROM memories WHERE agent=? ORDER BY id DESC LIMIT 10",(agent,))
    data=cur.fetchall(); conn.close(); return {"memories":data}
PY

echo "[4/5] Registering service..."
sudo tee /etc/systemd/system/etherverse-memory-gateway.service >/dev/null <<EOF
[Unit]
Description=Etherverse Memory Gateway
After=network.target redis-server.service

[Service]
WorkingDirectory=$MEM
ExecStart=$ROOT/venv/bin/uvicorn memory_gateway:app --host 0.0.0.0 --port 5055
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now etherverse-memory-gateway

echo "[5/5] Linking to Drive sync..."
sed -i '/--exclude "logs\/\*\*"/a \  --include "memory_core/**" \\' "$ROOT/scripts/drive_sync.sh"

echo "[✅] Hive Quantum Memory v2 installed and modular."
