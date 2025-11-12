#!/bin/bash
# ==========================================================
# Etherverse Hive Orchestrator Installer (safe edition)
# Builds a unified orchestration layer for all Etherverse agents
# ==========================================================
set -e
ROOT="$HOME/etherverse"
cd "$ROOT"

echo "[🚀] Building Etherverse Hive Orchestrator..."
python3 -m venv "$ROOT/venv" 2>/dev/null || true
source "$ROOT/venv/bin/activate"

echo "[📦] Installing dependencies..."
pip install -U pip wheel setuptools >/dev/null
pip install -U autogen crewai pyzmq chromadb sentence-transformers fastapi uvicorn requests >/dev/null

mkdir -p "$ROOT/core" "$ROOT/logs/hive_orchestrator" "$ROOT/memory"

# --- orchestrator main ---
cat > "$ROOT/core/hive_orchestrator.py" <<'PYCODE'
import os, json, requests, zmq, logging
from fastapi import FastAPI
from pydantic import BaseModel
from chromadb import Client
from chromadb.config import Settings
from sentence_transformers import SentenceTransformer, util

app = FastAPI(title="Etherverse Hive Orchestrator")
logger = logging.getLogger("hive")
logging.basicConfig(
    filename=os.path.expanduser("~/etherverse/logs/hive_orchestrator/main.log"),
    level=logging.INFO, format="%(asctime)s %(message)s")

# --- shared memory ---
client = Client(Settings(chroma_db_impl="duckdb+parquet",
                         persist_directory=os.path.expanduser("~/etherverse/memory")))
memory = client.get_or_create_collection("hive_memory")
model = SentenceTransformer("all-MiniLM-L6-v2")

# --- ZeroMQ message bus ---
ctx = zmq.Context()
pub = ctx.socket(zmq.PUB)
pub.bind("tcp://*:5555")

# --- autodiscover agents 8001-8031 ---
AGENTS = {f"agent_{p}": f"http://127.0.0.1:{p}" for p in range(8001, 8032)}

class Thought(BaseModel):
    intent: str
    data: dict | None = None

@app.post("/think")
def think(thought: Thought):
    intent = thought.intent
    results = {}
    for name, url in AGENTS.items():
        try:
            r = requests.post(f"{url}/think", json={"intent": intent}, timeout=5)
            results[name] = r.json().get("response", "")
        except Exception as e:
            results[name] = f"error: {e}"
    texts = list(results.values())
    if texts:
        emb = model.encode(texts, convert_to_tensor=True)
        score = float(util.cos_sim(emb.mean(0), emb).mean())
    else:
        score = 0
    memory.add(documents=texts, metadatas=[{"intent": intent}], ids=[intent[:32]])
    logger.info(f"[THINK] {intent} coherence={score:.3f}")
    return {"intent": intent, "coherence": score, "responses": results}

@app.get("/status")
def status():
    live = []
    for name, url in AGENTS.items():
        try:
            r = requests.get(f"{url}/docs", timeout=3)
            if r.status_code == 200:
                live.append(name)
        except: pass
    return {"live_agents": live, "count": len(live)}

@app.get("/memory/{query}")
def recall(query: str):
    return memory.query(query_texts=[query], n_results=5)

@app.on_event("startup")
def startup():
    logger.info("Hive Orchestrator online.")
PYCODE

echo "[✅] Hive Orchestrator installed at ~/etherverse/core/hive_orchestrator.py"
echo "To start manually run:"
echo "source ~/etherverse/venv/bin/activate && python -m uvicorn core.hive_orchestrator:app --host 0.0.0.0 --port 8080"
