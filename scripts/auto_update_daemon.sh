#!/usr/bin/env bash
# ============================================================
# ♻️  Etherverse Auto-Update Daemon (runs via systemd timer)
# ============================================================

LOG="$HOME/etherverse/logs/auto_update_$(date +%Y%m%d_%H%M).log"
VENV="$HOME/etherverse/venv"
mkdir -p "$(dirname "$LOG")"

{
echo "===================== $(date) ====================="
echo "[🧠] Running auto-update cycle…"

# --- activate environment
source "$VENV/bin/activate" 2>/dev/null || {
  echo "[🚧] Virtualenv missing — recreating"
  python3 -m venv "$VENV"
  source "$VENV/bin/activate"
}

# --- refresh package index
pip install -U pip setuptools wheel >/dev/null 2>&1

# --- safe upgrade block
pip install -U \
  "numpy<2" torch torchvision --index-url https://download.pytorch.org/whl/cpu \
  "pydantic<2.12" "fastapi<0.115" "gradio<5.50" \
  langchain chromadb google-api-python-client \
  google-auth google-auth-oauthlib google-auth-httplib2 \
  duckduckgo-search web3 ccxt requests >/dev/null 2>&1

# --- silent repair for known conflicts
pip check >/dev/null 2>&1 || {
  echo "[🔧] Repairing dependency mismatches"
  pip uninstall -y numpy torch pydantic fastapi >/dev/null 2>&1
  pip install "numpy<2" "torch==2.2.2+cpu" "pydantic<2.12" "fastapi<0.115" \
      --index-url https://download.pytorch.org/whl/cpu >/dev/null 2>&1
}

# --- restart orchestrator if needed
if pgrep -f "quantum_orchestrator" >/dev/null 2>&1; then
  echo "[♻️] Restarting orchestrator service"
  pkill -f quantum_orchestrator
  nohup bash "$HOME/etherverse/scripts/start_quantum_orchestrator.sh" >/dev/null 2>&1 &
fi

echo "[✅] Update cycle complete."
} >>"$LOG" 2>&1
