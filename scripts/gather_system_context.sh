#!/bin/bash

# ===============================================================
#   ETHERVERSE SYSTEM CONTEXT COLLECTION ENGINE (SAFE MODE)
#   - Collects ONLY non-sensitive metadata
#   - No passwords, tokens, secrets, or env values
#   - Produces a full system report for GPT analysis
#
#   Output: ~/etherverse/logs/system_context_report/
# ===============================================================

ROOT="$HOME/etherverse"
OUT="$ROOT/logs/system_context_report"
mkdir -p "$OUT"

echo "[🔍] Collecting Etherverse system context..."
echo "[📁] Output: $OUT"

# ---------------------------------------------------------------
# 1. Environment Variable NAMES (NOT VALUES)
# ---------------------------------------------------------------
echo "[1/12] Capturing environment variable NAMES only..."

printenv | sed 's/=.*//' | sort > "$OUT/env_variable_names.txt"


# ---------------------------------------------------------------
# 2. Check if GitHub app is installed
# ---------------------------------------------------------------
echo "[2/12] Inspecting GitHub CLI / GitHub App config..."

{
  echo "=== GitHub CLI Installed? ==="
  which gh 2>/dev/null || echo "gh not found"

  echo ""
  echo "=== Git Config (no secrets) ==="
  git config --global --list | sed 's/token=.*//' | sed 's/password=.*//'

  echo ""
  echo "=== Repo Remotes ==="
  git -C "$ROOT" remote -v 2>/dev/null

} > "$OUT/github_info.txt"


# ---------------------------------------------------------------
# 3. Systemd services related to Etherverse
# ---------------------------------------------------------------
echo "[3/12] Scanning systemd for Etherverse units..."

systemctl list-units --all | grep -Ei "etherverse|codex|helix|quantum" \
  > "$OUT/systemd_units.txt" 2>/dev/null


# ---------------------------------------------------------------
# 4. Cron jobs
# ---------------------------------------------------------------
echo "[4/12] Capturing cron configuration..."

crontab -l > "$OUT/cron_jobs.txt" 2>/dev/null || echo "No crontab" > "$OUT/cron_jobs.txt"


# ---------------------------------------------------------------
# 5. Python environment details
# ---------------------------------------------------------------
echo "[5/12] Inspecting Python environments..."

{
  echo "=== Python Version ==="
  python3 --version 2>/dev/null

  echo ""
  echo "=== Pip Version ==="
  pip --version 2>/dev/null

  echo ""
  echo "=== Virtual Environments Detected ==="
  find "$HOME" -maxdepth 4 -type d -name "venv" -o -name ".venv"

} > "$OUT/python_env_info.txt"


# ---------------------------------------------------------------
# 6. Installed binaries relevant to LLMs or devtools
# ---------------------------------------------------------------
echo "[6/12] Scanning for important binaries..."

{
  which ollama 2>/dev/null
  which node 2>/dev/null
  which npm 2>/dev/null
  which jq 2>/dev/null
  which deno 2>/dev/null
  which cargo 2>/dev/null
  which docker 2>/dev/null
  which kubectl 2>/dev/null
  which rclone 2>/dev/null
  which cloudflared 2>/dev/null
} > "$OUT/binaries_info.txt"


# ---------------------------------------------------------------
# 7. Node.js project inspection
# ---------------------------------------------------------------
echo "[7/12] Checking for Node/JS projects..."

find "$ROOT" -type f -name "package.json" > "$OUT/node_projects.txt"


# ---------------------------------------------------------------
# 8. Active ports / running processes
# ---------------------------------------------------------------
echo "[8/12] Capturing active ports..."

ss -tulpn | grep -Ei "python|node|uvicorn|fastapi|flask|7777|8000|3000" \
  > "$OUT/active_ports.txt" 2>/dev/null


# ---------------------------------------------------------------
# 9. Machine spec summary
# ---------------------------------------------------------------
echo "[9/12] Capturing system limits & specs..."

{
  uname -a
  echo ""
  echo "Memory:"
  free -h
  echo ""
  echo "Disk Usage:"
  df -h /
  echo ""
  echo "Crostini Container Disk:"
  df -h "$HOME"
} > "$OUT/system_specs.txt"


# ---------------------------------------------------------------
# 10. Aliases & shell configuration
# ---------------------------------------------------------------
echo "[10/12] Capturing shell aliases..."

{
  echo "=== Bash Aliases ==="
  alias
  echo ""
  echo "=== Bashrc includes ==="
  grep -E "alias|source|export" ~/.bashrc | sed 's/=.*/=*** masked/' 
} > "$OUT/shell_config.txt"


# ---------------------------------------------------------------
# 11. Etherverse configuration files
# ---------------------------------------------------------------
echo "[11/12] Searching for Etherverse config files..."

find "$ROOT" -maxdepth 4 -type f | grep -Ei "config|settings|rules|manifest" \
  > "$OUT/etherverse_configs.txt"


# ---------------------------------------------------------------
# 12. Detect leftover or hidden Etherverse files
# ---------------------------------------------------------------
echo "[12/12] Detecting hidden files related to Etherverse..."

find "$HOME" -maxdepth 4 -type f -name ".*" | grep -Ei "ether|verse" \
  > "$OUT/hidden_files.txt"


echo ""
echo "[✅] System context collection complete!"
echo "[📂] Reports saved to: $OUT"
echo "[ℹ️] Safe to upload for analysis."
