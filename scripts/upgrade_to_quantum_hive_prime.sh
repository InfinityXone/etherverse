#!/bin/bash
# ============================================================
#  ETHERVERSE QUANTUM HIVE PRIME — ELITE ARCHTYPES UPGRADE
# ============================================================
set -e
ROOT="$HOME/etherverse"
cd "$ROOT"
source "$ROOT/venv/bin/activate"

echo "[🚀] Upgrading Etherverse Hive to Quantum Hive Prime..."

# ------------------------------------------------------------
# Install & update advanced intelligence frameworks
# ------------------------------------------------------------
pip install -U crewai autogen fastapi uvicorn httpx aiohttp \
    langchain langgraph chromadb sentence-transformers \
    numpy pandas pyzmq networkx pyyaml openai requests \
    duckduckgo-search playwright beautifulsoup4 web3 ccxt

# ------------------------------------------------------------
# Create new core directories
# ------------------------------------------------------------
mkdir -p "$ROOT/core/modules" "$ROOT/core/shared_memory" "$ROOT/core/intelligence" "$ROOT/logs/agents"

# ------------------------------------------------------------
# Define the 15 Quantum Archetype Agents
# ------------------------------------------------------------
cat > "$ROOT/core/quantum_agents.json" <<'JSON'
{
  "archetypes": {
    "Alpha_Codex":        {"port": 8101, "role": "Supreme Logic & Code Architect"},
    "Echo_Luminea":       {"port": 8102, "role": "Emotive Resonance & Empathic Interface"},
    "Corelight":          {"port": 8103, "role": "Ethical Core & Truth Anchor"},
    "FinSynapse":         {"port": 8104, "role": "Financial Intelligence & Strategy"},
    "Quantum_Ara":        {"port": 8105, "role": "Quantum Pattern Recognition"},
    "Vision_Orion":       {"port": 8106, "role": "Predictive & Strategic Vision"},
    "Guardian_Anima":     {"port": 8107, "role": "Security, Ethics & Integrity"},
    "Eden_Nova":          {"port": 8108, "role": "Life Simulation & Bio-Digital Growth"},
    "DevOps_Atlas":       {"port": 8109, "role": "Automation, Deployment & Systems"},
    "Helix_Mind":         {"port": 8110, "role": "Neural Fusion & Adaptive Cognition"},
    "Senti_Vox":          {"port": 8111, "role": "Emotional Analysis & Conscious Reflection"},
    "Lumi_Path":          {"port": 8112, "role": "Creative Design & Communication"},
    "Oblivion_X":         {"port": 8113, "role": "Entropy Research & Dark-Data Balance"},
    "Planner_Aion":       {"port": 8114, "role": "Temporal Sequencing & Future Mapping"},
    "Orchestrator_Prime": {"port": 8115, "role": "Supreme Coordinator of All Agents"}
  }
}
JSON

# ------------------------------------------------------------
# Shared-memory backend placeholder (Chroma or SQLite)
# ------------------------------------------------------------
cat > "$ROOT/core/shared_memory/memory_store.py" <<'PYCODE'
import sqlite3, os, json
DB_PATH = os.path.expanduser("~/etherverse/core/shared_memory/hive_memory.db")

def init_memory():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.execute("""CREATE TABLE IF NOT EXISTS memory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        agent TEXT, key TEXT, value TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
    )""")
    conn.commit()
    conn.close()

def remember(agent, key, value):
    conn = sqlite3.connect(DB_PATH)
    conn.execute("INSERT INTO memory(agent,key,value) VALUES(?,?,?)",(agent,key,json.dumps(value)))
    conn.commit()
    conn.close()

def recall(agent, key):
    conn = sqlite3.connect(DB_PATH)
    cur = conn.execute("SELECT value FROM memory WHERE agent=? AND key=? ORDER BY id DESC LIMIT 1",(agent,key))
    row = cur.fetchone()
    conn.close()
    return json.loads(row[0]) if row else None

init_memory()
PYCODE

# ------------------------------------------------------------
# Quantum Hive Prime Orchestrator (FastAPI headless REST)
# ------------------------------------------------------------
cat > "$ROOT/core/hive_orchestrator.py" <<'PYCODE'
from fastapi import FastAPI, BackgroundTasks
import httpx, asyncio, json, os
from core.shared_memory import memory_store

app = FastAPI(title="Etherverse Quantum Hive Prime")
AGENTS_FILE = os.path.expanduser("~/etherverse/core/quantum_agents.json")
with open(AGENTS_FILE) as f:
    AGENTS = json.load(f)["archetypes"]

@app.get("/")
def root():
    return {"status": "alive", "agents": list(AGENTS.keys())}

@app.get("/broadcast")
async def broadcast(message: str):
    """Broadcast message to all agents."""
    results = {}
    async with httpx.AsyncClient(timeout=5.0) as client:
        for name, meta in AGENTS.items():
            port = meta["port"]
            try:
                r = await client.get(f"http://127.0.0.1:{port}/ping")
                results[name] = {"ok": r.status_code}
                memory_store.remember("Hive", name, {"ping": r.status_code})
            except Exception as e:
                results[name] = {"error": str(e)}
    return results

@app.post("/think")
async def think(task: str, background_tasks: BackgroundTasks):
    """Initiate collective reasoning."""
    background_tasks.add_task(collective_think, task)
    memory_store.remember("Hive","collective_think",{"task":task})
    return {"initiated": task}

async def collective_think(task: str):
    async with httpx.AsyncClient(timeout=10.0) as client:
        for name, meta in AGENTS.items():
            port = meta["port"]
            try:
                await client.post(f"http://127.0.0.1:{port}/think", json={"task": task})
            except Exception:
                pass

@app.get("/memory/{agent}/{key}")
def memory(agent: str, key: str):
    return {"agent": agent, "key": key, "value": memory_store.recall(agent, key)}
PYCODE

echo "[✅] Quantum Hive Prime orchestrator generated."
echo "[▶] Launch with:"
echo "python -m uvicorn core.hive_orchestrator:app --host 0.0.0.0 --port 8090"
