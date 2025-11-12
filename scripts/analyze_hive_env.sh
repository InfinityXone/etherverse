#!/bin/bash
# ==========================================================
# Etherverse Hive Environment Analyzer
# Scans ~/etherverse to report structure, Python envs,
# agent locations, memory folders, and network exposure.
# ==========================================================

ROOT="$HOME/etherverse"
REPORT="$ROOT/hive_env_report.json"

echo "[🔍] Scanning Etherverse environment..."
mkdir -p "$(dirname "$REPORT")"

# --- basic system info ---
PY=$(command -v python3 || command -v python)
PY_VER=$($PY -V 2>&1)
PIP_VER=$($PY -m pip -V 2>/dev/null)

# --- check for virtual environments ---
VENV_PATHS=$(find "$ROOT" -type d -name "venv" 2>/dev/null | tr '\n' ',')

# --- list agent modules ---
AGENT_FOLDERS=$(find "$ROOT/agents" -maxdepth 2 -type f -name "agent.py" 2>/dev/null | sed "s|$ROOT/||" | sort)

# --- check memory directories ---
MEM_DIRS=$(find "$ROOT" -type d -name "memory" 2>/dev/null | tr '\n' ',')

# --- check for orchestration frameworks installed ---
CREW=$(pip show crewai 2>/dev/null | grep -E '^Version:' | awk '{print $2}')
AUTOGEN=$(pip show autogen 2>/dev/null | grep -E '^Version:' | awk '{print $2}')
ZEROMQ=$(pip show pyzmq 2>/dev/null | grep -E '^Version:' | awk '{print $2}')
CHROMA=$(pip show chromadb 2>/dev/null | grep -E '^Version:' | awk '{print $2}')

# --- detect active FastAPI/uvicorn services (if running) ---
PORTS=$(ss -tuln 2>/dev/null | grep -E ':8[0-9]{3}' | awk '{print $5}' | cut -d':' -f2 | sort -u | tr '\n' ',')

# --- assemble JSON output ---
cat > "$REPORT" <<JSON
{
  "python_path": "$PY",
  "python_version": "$PY_VER",
  "pip_version": "$PIP_VER",
  "virtual_envs": "$VENV_PATHS",
  "agent_files": [
$(echo "$AGENT_FOLDERS" | awk '{printf "    \"%s\",\n", $0}' | sed '$s/,$//')
  ],
  "memory_directories": "$MEM_DIRS",
  "installed_frameworks": {
    "crewai": "$CREW",
    "autogen": "$AUTOGEN",
    "zeromq": "$ZEROMQ",
    "chromadb": "$CHROMA"
  },
  "open_ports_8000s": "$PORTS"
}
JSON

echo "[✅] Analysis complete."
echo "Report saved to: $REPORT"
echo "----------------------------------------------------------"
cat "$REPORT" | jq .
echo "----------------------------------------------------------"
echo "Paste this JSON back into ChatGPT so I can build the exact unification script."
