#!/bin/bash
echo "[🧠] Initializing Etherverse Agents..."
# 1. hydrate shared memory
python3 core/memory_summarizer.py 2>/dev/null || echo "memory_summarizer not found."
# 2. launch each primary agent in background
for agent in codex echo guardian pickybot corelight finsynapse; do
  if [ -f "agents/${agent}.py" ]; then
    echo "[⚡] Starting $agent..."
    nohup python3 "agents/${agent}.py" > "logs/${agent}.log" 2>&1 &
  else
    echo "[⚠] Agent file missing: agents/${agent}.py"
  fi
done
echo "[✅] All available agents launched."
