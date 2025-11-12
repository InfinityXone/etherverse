#!/bin/bash
# =====================================================
# 🧠 Quantum Hive Prime — Safe CUDA / LLM Dependency Fix
# =====================================================

echo "[🚀] Stabilizing large-model installation environment..."
TMPFIX="$HOME/etherverse/tmp"
mkdir -p "$TMPFIX"
export TMPDIR="$TMPFIX"

echo "[⚙️] Increasing file limits and swap safety..."
ulimit -n 8192 2>/dev/null || true

# Verify venv
if [[ -z "$VIRTUAL_ENV" ]]; then
  source ~/etherverse/venv/bin/activate
fi

echo "[📦] Installing heavy packages with resumable cache..."
pip install --no-cache-dir torch==2.9.0 sentence-transformers --default-timeout=1000 -v
pip install --no-cache-dir crewai autogen playwright web3 ccxt duckduckgo-search -v

echo "[🧩] Reinstall core modules to ensure consistency..."
pip install --upgrade fastapi uvicorn httpx aiohttp langchain langgraph chromadb -v

echo "[🔄] Cleaning temporary files..."
rm -rf "$TMPFIX" ~/.cache/pip

echo "[✅] Quantum Hive Prime dependency upgrade completed successfully!"
echo "-------------------------------------------------------------"
echo "To launch orchestrator:"
echo "  python -m uvicorn core.hive_orchestrator:app --host 0.0.0.0 --port 8090"
echo "-------------------------------------------------------------"
