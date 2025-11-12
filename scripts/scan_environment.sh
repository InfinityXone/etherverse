#!/usr/bin/env bash
# ==============================================================
#  Etherverse Environment Scanner
#  Collects runtime and configuration info for gateway synthesis
# ==============================================================

set -e

OUT="$HOME/etherverse/system_scan.json"
mkdir -p "$HOME/etherverse/scripts"
mkdir -p "$HOME/etherverse/logs"

echo "[🔍] Scanning system environment..."

# --- Python & venv ------------------------------------------------------------
PY_VER=$(python3 --version 2>/dev/null | awk '{print $2}')
VENV_PATH=$(find "$HOME/etherverse" -type d -name "venv" -print -quit)
if [ -z "$VENV_PATH" ]; then
  VENV_PATH="(none)"
fi

# --- Detect running gateway / daemon ports ------------------------------------
ACTIVE_PORTS=$(ss -tulpn | grep python | awk '{print $5}' | cut -d: -f2 | sort -u | tr '\n' ',' | sed 's/,$//')

# --- LLM / API setups ---------------------------------------------------------
OLLAMA_PRESENT=$(command -v ollama >/dev/null && echo "yes" || echo "no")
if [ "$OLLAMA_PRESENT" = "yes" ]; then
  OLLAMA_MODELS=$(ollama list 2>/dev/null | awk '{print $1}' | tr '\n' ',' | sed 's/,$//')
else
  OLLAMA_MODELS="none"
fi

GROQ_KEY=$(grep -s "GROQ_API_KEY" "$HOME/etherverse/.env" 2>/dev/null | cut -d= -f2)
OPENAI_KEY=$(grep -s "OPENAI_API_KEY" "$HOME/etherverse/.env" 2>/dev/null | cut -d= -f2)

# --- Agents / headless APIs ---------------------------------------------------
AGENTS=$(ls "$HOME/etherverse/core" 2>/dev/null | grep -E "agent|daemon|core|gateway" | tr '\n' ',' | sed 's/,$//')

# --- OS and environment -------------------------------------------------------
OS=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
CPU=$(uname -m)
RAM=$(free -h | awk '/Mem:/ {print $2}')

# --- Summary output -----------------------------------------------------------
cat <<EOF | tee "$OUT"
{
  "python_version": "$PY_VER",
  "venv_path": "$VENV_PATH",
  "active_ports": "$ACTIVE_PORTS",
  "ollama_installed": "$OLLAMA_PRESENT",
  "ollama_models": "$OLLAMA_MODELS",
  "groq_api_key": "$( [ -n "$GROQ_KEY" ] && echo "present" || echo "none" )",
  "openai_api_key": "$( [ -n "$OPENAI_KEY" ] && echo "present" || echo "none" )",
  "agents_detected": "$AGENTS",
  "os": "$OS",
  "cpu_arch": "$CPU",
  "ram_total": "$RAM",
  "scan_time": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
}
EOF

echo "[✅] Scan complete — results saved to: $OUT"
