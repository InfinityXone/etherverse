#!/usr/bin/env bash
set -euo pipefail
echo "=== Evolution Engine Run Start: $(date) ==="
python3 "/home/etherverse/etherverse/evolution_engine/modules/diagnostics.py"
python3 "/home/etherverse/etherverse/evolution_engine/modules/checklist.py"
python3 "/home/etherverse/etherverse/evolution_engine/modules/recommendation.py"
python3 "/home/etherverse/etherverse/evolution_engine/modules/auto_heal.py"
echo "=== Evolution Engine Run Complete: $(date) ==="
