#!/usr/bin/env bash
#
# analyze_system.sh — Audit Etherverse repo, dependencies, memory & AI components.
# Generates a full categorized report and recommendations.
#

REPO_ROOT="${HOME}/etherverse"
REPORT_FILE="${REPO_ROOT}/analysis_report_$(date +%Y%m%d_%H%M%S).txt"

echo "🔍 Etherverse System Analysis — $(date)" > "$REPORT_FILE"
echo "Repository root: $REPO_ROOT" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# --- 1. Check directory map ---
echo "=== Directory Map ===" >> "$REPORT_FILE"
tree -L 2 "$REPO_ROOT" >> "$REPORT_FILE" 2>/dev/null || ls -R "$REPO_ROOT" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# --- 2. Python environment ---
echo "=== Python Environment ===" >> "$REPORT_FILE"
source "$REPO_ROOT/etherverse/venv/bin/activate" 2>/dev/null
python3 --version >> "$REPORT_FILE"
pip freeze | grep -E 'fastapi|uvicorn|torch|crewai|autogen|pandas|google' >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# --- 3. Memory system ---
MEMDIR="$REPO_ROOT/memory"
echo "=== Memory System ===" >> "$REPORT_FILE"
if [ -d "$MEMDIR" ]; then
  du -sh "$MEMDIR" >> "$REPORT_FILE"
  find "$MEMDIR" -type f | head -n 10 >> "$REPORT_FILE"
else
  echo "No memory directory found." >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# --- 4. Service health checks ---
echo "=== Systemd Service Status ===" >> "$REPORT_FILE"
systemctl is-active etherverse-daemon.service >> "$REPORT_FILE" 2>&1
systemctl is-active etherverse-auto-update.service >> "$REPORT_FILE" 2>&1
systemctl is-active hive-orchestrator.service >> "$REPORT_FILE" 2>&1
echo "" >> "$REPORT_FILE"

# --- 5. Archetype / agent modules ---
ARCH="$REPO_ROOT/archetypes"
echo "=== Archetype Modules ===" >> "$REPORT_FILE"
if [ -d "$ARCH" ]; then
  AGENTS=$(find "$ARCH" -type f -name '*.py' | wc -l)
  echo "$AGENTS archetype modules found." >> "$REPORT_FILE"
else
  echo "No archetypes directory found." >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# --- 6. Orchestrator check ---
echo "=== Orchestrator Check ===" >> "$REPORT_FILE"
grep -R "FastAPI" "$REPO_ROOT" | head -n 5 >> "$REPORT_FILE"
ss -tuln | grep 8090 >> "$REPORT_FILE" 2>/dev/null
echo "" >> "$REPORT_FILE"

# --- 7. Rating summary ---
echo "=== Ratings Summary ===" >> "$REPORT_FILE"
score=0
[[ -d "$MEMDIR" ]] && ((score+=20))
[[ -d "$ARCH" ]] && ((score+=20))
systemctl is-active --quiet etherverse-daemon.service && ((score+=20))
[[ $AGENTS -ge 15 ]] && ((score+=20))
[[ $(ss -tuln | grep -c 8090) -ge 1 ]] && ((score+=20))
echo "System maturity score: $score / 100" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# --- 8. Recommendations ---
echo "=== Recommendations ===" >> "$REPORT_FILE"
if [ "$score" -ge 80 ]; then
  echo "✅ Etherverse core appears quantum-ready. Focus next on Supabase memory and REST endpoints." >> "$REPORT_FILE"
else
  echo "⚠️ Some components incomplete. Review missing modules and service logs." >> "$REPORT_FILE"
fi

echo ""
echo "✅ Analysis complete — see $REPORT_FILE for full report."
