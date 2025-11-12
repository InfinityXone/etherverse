#!/usr/bin/env bash
#
# full_system_report.sh — comprehensive analysis of Etherverse system.
# Usage: cd ~/etherverse && ./scripts/full_system_report.sh
#

REPO_ROOT="$HOME/etherverse"
REPORT_TS=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="$REPO_ROOT/full_system_report_$REPORT_TS.txt"

echo "🔍 Etherverse Full System Report — $(date)" > "$REPORT_FILE"
echo "Repository root: $REPO_ROOT" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

section() {
  echo "=== $1 ===" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
}

# 1. Infrastructure & Services
section "1. Infrastructure & Services"
echo "Checking key service statuses:" >> "$REPORT_FILE"
for svc in etherverse-daemon.service etherverse-auto-update.service; do
  status=$(systemctl is-active $svc 2>/dev/null || echo "unknown")
  echo "  Service $svc : $status" >> "$REPORT_FILE"
done
echo "" >> "$REPORT_FILE"

# 2. Codebase Structure
section "2. Codebase Structure & Modules"
echo "Directory tree (top 2 levels):" >> "$REPORT_FILE"
tree -L 2 "$REPO_ROOT" 2>/dev/null >> "$REPORT_FILE" || ls -R "$REPO_ROOT" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 3. Agent Modules
section "3. Agent Modules"
AGENT_DIR="$REPO_ROOT/agents"
if [ -d "$AGENT_DIR" ]; then
  count=$(find "$AGENT_DIR" -type f -name '*.py' | wc -l)
  echo "  Agent module (.py) count: $count" >> "$REPORT_FILE"
else
  echo "  Agent directory not found: $AGENT_DIR" >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# 4. Memory & Persistence
section "4. Memory & Persistence Layer"
MEM_DIR="$REPO_ROOT/memory"
if [ -d "$MEM_DIR" ]; then
  size=$(du -sh "$MEM_DIR" 2>/dev/null | cut -f1)
  echo "  Memory directory: present" >> "$REPORT_FILE"
  echo "  Size: $size" >> "$REPORT_FILE"
else
  echo "  Memory directory not found." >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# 5. Dependencies & Runtime
section "5. Dependencies & Runtime"
if [ -f "$REPO_ROOT/venv/bin/activate" ]; then
  echo "  Virtualenv found." >> "$REPORT_FILE"
  source "$REPO_ROOT/venv/bin/activate"
  python --version >> "$REPORT_FILE"
  pip freeze | grep -E 'fastapi|uvicorn|torch|crewai|autogen|google-auth' >> "$REPORT_FILE"
  deactivate
else
  echo "  Virtualenv not found in $REPO_ROOT/venv" >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# 6. Orchestrator & API
section "6. Orchestrator & API Endpoints"
echo "Listening ports for orchestrator:" >> "$REPORT_FILE"
ss -tuln | grep 8090 >> "$REPORT_FILE" 2>/dev/null
echo "" >> "$REPORT_FILE"

# 7. Rating Summary
section "7. Rating Summary"
score=0
# +20 if services healthy
[[ $(systemctl is-active etherverse-daemon.service) == "active" ]] && score=$((score+20))
# +20 if 10+ agent modules
[[ $count -ge 10 ]] && score=$((score+20))
# +20 if memory folder present
[[ -d "$MEM_DIR" ]] && score=$((score+20))
# +20 if virtualenv and key deps found
if [ -f "$REPO_ROOT/venv/bin/activate" ]; then
  score=$((score+20))
fi
# +20 if API port active
if ss -tuln | grep -q 8090; then
  score=$((score+20))
fi
echo "  System maturity score: $score / 100" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 8. Missing / Gaps
section "8. Missing or Weak Areas"
if [ ! -d "$MEM_DIR" ]; then
  echo "  - Memory/persistence layer is missing." >> "$REPORT_FILE"
fi
if [ $count -lt 15 ]; then
  echo "  - Agent module count ($count) is below target (15)." >> "$REPORT_FILE"
fi
if ! ss -tuln | grep -q 8090; then
  echo "  - Orchestrator API port 8090 not found listening." >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# 9. Recommendations
section "9. Recommendations"
echo "  1. Increase agent modules to at least 15 distinct archetypes." >> "$REPORT_FILE"
echo "  2. Ensure full shared memory bus, semantic vector DB and reflection loops." >> "$REPORT_FILE"
echo "  3. Build or verify UI/dashboard for orchestrator and agents." >> "$REPORT_FILE"
echo "  4. Validate all service health and auto-heal logs for full reliability." >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Print to terminal
cat "$REPORT_FILE"

echo ""
echo "✅ Full system report generated: $REPORT_FILE"
