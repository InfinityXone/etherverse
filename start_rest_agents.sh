#!/bin/bash

source "$HOME/etherverse/venv/bin/activate"
export PYTHONPATH="$HOME/etherverse"

# === Etherverse Multi-Agent REST Launcher ===
echo "🚀 Launching Etherverse REST agents..."
base="$HOME/etherverse/agents"
log="$HOME/etherverse/logs/rest_agents"
mkdir -p "$log"

port=8001
for agent in $(find "$base" -maxdepth 2 -type f -name "agent.py"); do
  name=$(basename "$(dirname "$agent")")
  echo "[🔧] Starting $name on port $port"
  nohup uvicorn "$(basename "$agent" .py)":app \
         --app-dir "$(dirname "$agent")" \
         --host 0.0.0.0 --port $port > "$log/$name.out" 2>&1 &
  ((port++))
done

echo "✅ All REST agents launched. Logs in: $log"
