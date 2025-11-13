#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# 🌐 Etherverse Enterprise Memory System Bootstrapper
# ============================================================

ROOT="$HOME/etherverse"
MEM="$ROOT/memory"
LOG="$ROOT/logs/memory_bootstrap_$(date +%Y%m%d_%H%M).log"

echo "[🚀] Bootstrapping Etherverse Enterprise Memory System..."
mkdir -p "$ROOT/logs"

echo "[🧠] Creating directory structure..." | tee "$LOG"

mkdir -p "$MEM"
mkdir -p "$MEM/data"
mkdir -p "$MEM/chroma"
mkdir -p "$MEM/reflection"
mkdir -p "$MEM/graph"
mkdir -p "$MEM/scripts"
mkdir -p "$MEM/gateway"
mkdir -p "$MEM/client"

# =========================
#  INSTALL DEPENDENCIES
# =========================
echo "[📦] Installing Python dependencies..." | tee -a "$LOG"
source "$ROOT/venv/bin/activate"

pip install --upgrade \
    fastapi \
    uvicorn \
    chromadb \
    sentence-transformers \
    networkx \
    matplotlib \
    redis \
    pandas \
    scikit-learn \
    pydantic \
    langchain \
    langgraph

# =========================
#  BUILD: Graph Layer
# =========================
echo "[📘] Installing graph cognition module..." | tee -a "$LOG"

cat > "$MEM/graph/graph_layer.py" << 'EOF'
<GRAPH_LAYER_WILL_BE_INSERTED_HERE>
EOF

# =========================
#  BUILD: Semantic Layer
# =========================
echo "[🔍] Installing semantic layer..." | tee -a "$LOG"

cat > "$MEM/semantic_layer.py" << 'EOF'
from langchain.embeddings import HuggingFaceEmbeddings
import chromadb, os

CHROMA_PATH = os.path.expanduser("~/etherverse/memory/chroma")
client = chromadb.PersistentClient(path=CHROMA_PATH)
collection = client.get_or_create_collection("hive_semantic")

embedder = HuggingFaceEmbeddings(model_name="sentence-transformers/all-MiniLM-L6-v2")

def store(agent, text):
    vec = embedder.embed_query(text)
    collection.add(
        documents=[text],
        metadatas=[{"agent": agent}],
        ids=[str(hash(text))]
    )

def search(query, k=5):
    qv = embedder.embed_query(query)
    res = collection.query(query_embeddings=[qv], n_results=k)
    return res["documents"][0]
EOF

# =========================
#  BUILD: Reflection Loop
# =========================
echo "[🌙] Installing reflection & dream engine..." | tee -a "$LOG"

cat > "$MEM/reflection/reflection_loop.py" << 'EOF'
#!/usr/bin/env python3
import os, sqlite3, random, datetime

from memory.semantic_layer import store
from memory.graph.graph_layer import link, save

DB = os.path.expanduser("~/etherverse/memory/data/hive_local.db")
LOG = os.path.expanduser("~/etherverse/logs/reflection.log")

def reflect_and_dream():
    print("[🌙] Starting nightly reflection…")
    conn = sqlite3.connect(DB)
    cur = conn.execute("SELECT agent,content FROM memories WHERE created_at>datetime('now','-1 day')")
    entries = cur.fetchall()
    agents_today = set()

    for agent, content in entries:
        agents_today.add(agent)
        lesson = f"Lesson: {content[:150]}... Insight: {random.choice(['Optimize', 'Coordinate', 'Improve', 'Adapt'])}"
        store(agent, lesson)
        conn.execute("INSERT INTO memories(agent,event,content) VALUES(?,?,?)",
                     (agent,"reflection",lesson))

    # Build relationship graph
    agents = list(agents_today)
    for i, a in enumerate(agents):
        for b in agents[i+1:]:
            link(a, b, "co_evolved_with")

    conn.commit()
    conn.close()
    save()

    with open(LOG,"a") as f:
        f.write(f"[{datetime.datetime.now()}] Stored {len(entries)} reflections\n")

if __name__ == "__main__":
    reflect_and_dream()
EOF

chmod +x "$MEM/reflection/reflection_loop.py"

# =========================
#  BUILD: Self-Heal Module
# =========================
echo "[⚕️] Installing anomaly detection..." | tee -a "$LOG"

cat > "$MEM/reflection/selfheal_reflection.py" << 'EOF'
import sqlite3, pandas as pd
from sklearn.ensemble import IsolationForest

DB = "~/etherverse/memory/data/hive_local.db"

def selfheal():
    conn = sqlite3.connect(os.path.expanduser(DB))
    df = pd.read_sql("SELECT length(content) as size FROM memories",conn)
    model = IsolationForest(contamination=0.03).fit(df)
    df['outlier'] = model.predict(df[['size']])
    issues = df[df.outlier == -1]
    print("[⚕️] Found", len(issues), "anomalies")
    conn.close()

if __name__ == "__main__":
    selfheal()
EOF

# =========================
#  BUILD: Memory Gateway
# =========================
echo "[🌐] Installing memory gateway microservice..." | tee -a "$LOG"

cat > "$MEM/gateway/memory_gateway.py" << 'EOF'
from fastapi import FastAPI
import sqlite3, datetime, os

app = FastAPI()

DB = os.path.expanduser("~/etherverse/memory/data/hive_local.db")

@app.post("/write")
def write(agent:str, event:str, content:str):
    conn = sqlite3.connect(DB)
    conn.execute(
      "INSERT INTO memories(agent,event,content,created_at) VALUES(?,?,?,?)",
      (agent,event,content,datetime.datetime.utcnow().isoformat())
    )
    conn.commit()
    conn.close()
    return {"status":"ok"}

@app.get("/query")
def query(agent:str):
    conn = sqlite3.connect(DB)
    cur = conn.execute("SELECT event,content FROM memories WHERE agent=? ORDER BY id DESC LIMIT 20",(agent,))
    out = cur.fetchall()
    conn.close()
    return {"memories":out}
EOF

# =========================
#  REGISTER SYSTEMD SERVICE
# =========================
echo "[⚙️] Registering memory gateway service..." | tee -a "$LOG"

sudo tee /etc/systemd/system/etherverse-memory.service >/dev/null << EOF
[Unit]
Description=Etherverse Memory Gateway
After=network.target

[Service]
WorkingDirectory=$MEM/gateway
ExecStart=$ROOT/venv/bin/uvicorn memory_gateway:app --host 0.0.0.0 --port 5055
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now etherverse-memory.service

# =========================
#  DRIVE SYNC INTEGRATION
# =========================
echo "[☁️] Updating Drive sync script..." | tee -a "$LOG"

sed -i '/--exclude "logs\/\*\*"/a \  --include "memory/**" \\' "$ROOT/scripts/drive_sync.sh" || true

echo "[🎉] Enterprise Memory System Ready!"
echo "[📄] Bootstrap log: $LOG"
