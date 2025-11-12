#!/bin/bash
echo "[🔍] Scanning for Etherverse agents in ~/etherverse ..."
search_root="$HOME/etherverse"

# Look for likely agent files (.py, .sh, .md) containing the word "agent" or known agent names
find "$search_root" -type f \( -iname "*agent*" -o -iname "codex*" -o -iname "echo*" -o -iname "guardian*" -o -iname "pickybot*" -o -iname "corelight*" -o -iname "finsynapse*" \) \
  -printf "%p\n" | sort | tee ~/etherverse/agents_found.log

echo ""
echo "[📁] Results saved to ~/etherverse/agents_found.log"
echo "[✅] Scan complete."
