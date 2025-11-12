#!/bin/bash
# ==========================================================
# Etherverse – Repair + Upgrade Script
# Re-installs core dependencies and extends Hive Orchestrator.
# ==========================================================
set -e
ROOT="$HOME/etherverse"
cd "$ROOT"

echo "[🧩] Activating virtual environment..."
python3 -m venv "$ROOT/venv" 2>/dev/null || true
source "$ROOT/venv/bin/activate"

echo "[📦] Repairing dependencies (visible output)..."
pip install -U pip wheel setuptools
pip install -U autogen crewai pyzmq chromadb sentence-transformers fastapi uvicorn requests \
              playwright beautifulsoup4 requests-html ccxt web3 pandas numpy \
              camel-ai warp-drive maslab streamlit plotly gradio litellm openai

# --- Verify that hive_orchestrator.py exists ---
if [ ! -f "$ROOT/core/hive_orchestrator.py" ]; then
  echo "[❗] Orchestrator file missing; re-create base version..."
  cat > "$ROOT/core/hive_orchestrator.py" <<'PYCODE'
from fastapi import FastAPI
app = FastAPI(title="Etherverse Hive Orchestrator")
@app.get("/") 
def home(): 
    return {"status": "alive"}
PYCODE
fi

echo "[🔧] Repair complete.  Run orchestrator with:"
echo "source ~/etherverse/venv/bin/activate && python -m uvicorn core.hive_orchestrator:app --host 0.0.0.0 --port 8080"
