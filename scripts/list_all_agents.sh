#!/bin/bash
# ==============================================
#  Etherverse Agent Auditor v1.0
#  Purpose: list all agents and key stats
# ==============================================
AGENTS_DIR="$HOME/etherverse/agents"
LOG="$HOME/etherverse/logs/agent_audit_$(date +%Y%m%d_%H%M%S).txt"
CSV="$HOME/etherverse/logs/agent_audit_$(date +%Y%m%d_%H%M%S).csv"

mkdir -p "$HOME/etherverse/logs"

echo "[🔍] Scanning Etherverse agents in $AGENTS_DIR ..."
echo "Agent Name | Path | Lines | Size (KB) | Last Modified" > "$LOG"
echo "Agent,Path,Lines,SizeKB,Modified" > "$CSV"

find "$AGENTS_DIR" -maxdepth 2 -type f -name "agent.py" | sort | while read agent_file; do
  agent_name=$(basename "$(dirname "$agent_file")")
  line_count=$(wc -l < "$agent_file")
  size_kb=$(du -k "$agent_file" | cut -f1)
  modified=$(date -r "$agent_file" "+%Y-%m-%d %H:%M:%S")
  echo "$agent_name | $agent_file | $line_count | $size_kb | $modified" >> "$LOG"
  echo "$agent_name,$agent_file,$line_count,$size_kb,$modified" >> "$CSV"
done

TOTAL=$(find "$AGENTS_DIR" -maxdepth 2 -type f -name "agent.py" | wc -l)
echo "" >> "$LOG"
echo "[✅] Found $TOTAL agents." >> "$LOG"
echo "[📁] Report saved to $LOG and $CSV"
echo "[⚙️] To view: cat $LOG | less"
