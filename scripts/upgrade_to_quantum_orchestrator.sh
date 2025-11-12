#!/bin/bash
# ============================================================
# ⚛️ Etherverse Quantum Orchestrator — Full Upgrade & Launch
# ============================================================

set -e
VENV_PATH="$HOME/etherverse/venv/bin/activate"
ORCH_PATH="$HOME/etherverse/core/hive_orchestrator.py"
LOG_PATH="$HOME/etherverse/logs"
APP_MODULE="core.hive_orchestrator:app"
PORT=8090

echo "============================================================"
echo "🚀 Upgrading Etherverse Hive → Quantum Orchestrator..."
echo "============================================================"

# --- 1. Ensure environment ---
if [ ! -f "$VENV_PATH" ]; then
  echo "⚙️  Creating venv..."
  python3 -m venv "$HOME/etherverse/venv"
fi
source "$VENV_PATH"

# --- 2. Update packages ---
echo "📦 Updating dependencies..."
pip install -U pip wheel setuptools >/dev/null
pip install -U fastapi uvicorn httpx aiohttp pydantic langchain langgraph chromadb crewai autogen sentence-transformers duckduckgo-search web3 ccxt >/dev/null

# --- 3. Create orchestrator if missing ---
mkdir -p "$(dirname "$ORCH_PATH")"
if [ ! -f "$ORCH_PATH" ]; then
cat <<'EOF' > "$ORCH_PATH"
from fastapi import FastAPI
import os, json, time

app = FastAPI(title="Quantum Orchestrator", version="1.0")

@app.get("/")
async def root():
    return {"status": "quantum-online", "message": "Quantum Orchestrator responding"}

@app.get("/agents")
async def list_agents():
    agents_dir = os.path.expanduser("~/etherverse/agents")
    agents = [a for a in os.listdir(agents_dir) if os.path.isdir(os.path.join(agents_dir, a))]
    return {"agents": agents, "count": len(agents)}

@app.get("/reflect")
async def reflect():
    journal_path = os.path.expanduser("~/etherverse/memory/journal_reflection.log")
    os.makedirs(os.path.dirname(journal_path), exist_ok=True)
    with open(journal_path, "a") as f:
        f.write(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] Quantum reflection logged.\n")
    return {"reflection": "logged", "timestamp": time.strftime('%Y-%m-%d %H:%M:%S')}
EOF
fi

# --- 4. Sync Hive Manifest ---
echo "🧠 Building Hive Manifest..."
python3 <<'PYTHON'
import os, json, time
root = os.path.expanduser("~/etherverse")
agents_dir = os.path.join(root, "agents")
manifest = {
    "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
    "agents": [a for a in os.listdir(agents_dir) if os.path.isdir(os.path.join(agents_dir, a))],
    "memory_files": []
}
for path, _, files in os.walk(os.path.join(root, "memory")):
    for f in files:
        if f.endswith((".db", ".json", ".txt", ".log")):
            manifest["memory_files"].append(os.path.join(path, f))
with open(os.path.join(root, "logs/hive_manifest.json"), "w") as f:
    json.dump(manifest, f, indent=2)
print("✅ Hive Manifest updated.")
PYTHON

# --- 5. Rotate and restart orchestrator ---
echo "🔄 Restarting Quantum Orchestrator..."
mkdir -p "$LOG_PATH"
pkill -f "uvicorn.*$APP_MODULE" 2>/dev/null || true
nohup python3 -m uvicorn "$APP_MODULE" --host 0.0.0.0 --port $PORT --reload >"$LOG_PATH/hive_orchestrator.log" 2>&1 &

sleep 3
if pgrep -f "uvicorn.*$APP_MODULE" >/dev/null; then
  echo "✅ Quantum Orchestrator running on port $PORT"
  echo "📜 Logs: $LOG_PATH/hive_orchestrator.log"
else
  echo "❌ Failed to start. See logs:"
  tail -n 20 "$LOG_PATH/hive_orchestrator.log"
fi
echo "============================================================"
echo "🌐 Access: http://127.0.0.1:$PORT"
echo "⚛️ Quantum Orchestrator upgrade complete."
echo "============================================================"
