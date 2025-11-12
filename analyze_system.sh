#!/usr/bin/env bash
#
# analyze_system.sh — Analyze Etherverse repo, dependencies, memory & AI components.
# Usage: cd ~/etherverse && ./analyze_system.sh
#

REPO_ROOT="$(pwd)"
REPORT_FILE="${REPO_ROOT}/analysis_report_$(date +%Y%m%d_%H%M%S).txt"

echo "Analysis started at $(date)" > "$REPORT_FILE"
echo "Repository root: $REPO_ROOT" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 1. Directory structure summary
echo "=== Directory Structure ===" >> "$REPORT_FILE"
tree -L 2 . >> "$REPORT_FILE" 2>/dev/null || ls -R | sed 's/^/   /' >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 2. Python dependencies
echo "=== Python Dependencies (requirements.txt if exists) ===" >> "$REPORT_FILE"
if [ -f requirements.txt ]; then
  pip freeze 2>/dev/null | sed 's/^/   /' >> "$REPORT_FILE"
else
  echo "   No requirements.txt found. Listing installed packages:" >> "$REPORT_FILE"
  pip freeze 2>/dev/null | sed 's/^/   /' >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# 3. Memory folder overview
MEMORY_DIR="${REPO_ROOT}/memory"
echo "=== Memory Folder Status ===" >> "$REPORT_FILE"
if [ -d "$MEMORY_DIR" ]; then
  echo "   Found memory directory: $MEMORY_DIR" >> "$REPORT_FILE"
  du -sh "$MEMORY_DIR" >> "$REPORT_FILE"
  echo "   Top 10 largest files in memory:" >> "$REPORT_FILE"
  find "$MEMORY_DIR" -type f -exec ls -lh {} + | sort -k5 -hr | head -n 10 | sed 's/^/   /' >> "$REPORT_FILE"
else
  echo "   Memory directory not found." >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# 4. Agent modules count
ARCH_DIR="${REPO_ROOT}/archetypes"
echo "=== Archetype Agents Overview ===" >> "$REPORT_FILE"
if [ -d "$ARCH_DIR" ]; then
  echo "   Found archetypes directory: $ARCH_DIR" >> "$REPORT_FILE"
  AGENT_COUNT=$(find "$ARCH_DIR" -maxdepth 1 -type f -name '*.py' | wc -l)
  echo "   Number of agent modules (.py files): $AGENT_COUNT" >> "$REPORT_FILE"
else
  echo "   Archetypes directory not found." >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# 5. Orchestrator check
ORCH_FILE=$(find "$REPO_ROOT" -maxdepth 2 -type f -name 'orchestrator*.py' | head -n1)
echo "=== Orchestrator Status ===" >> "$REPORT_FILE"
if [ -n "$ORCH_FILE" ]; then
  echo "   Found orchestrator file: $ORCH_FILE" >> "$REPORT_FILE"
  grep -R "def main" -n "$ORCH_FILE" | head -n3 | sed 's/^/   /' >> "$REPORT_FILE"
else
  echo "   No orchestrator file found meeting pattern 'orchestrator*.py'." >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# 6. Sandbox / safety wrappers
echo "=== Safety & Sandbox Indicators ===" >> "$REPORT_FILE"
SANDBOX_INDICATORS=$(grep -R "sandbox" -n . | head -n5)
if [ -n "$SANDBOX_INDICATORS" ]; then
  echo "   Found sandbox references:" >> "$REPORT_FILE"
  echo "$SANDBOX_INDICATORS" | sed 's/^/   /' >> "$REPORT_FILE"
else
  echo "   No explicit sandbox/flag references found. Recommend adding." >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# 7. Quick Rating Logic
echo "=== Quick Ratings ===" >> "$REPORT_FILE"
rate_dir() {
  local d="\$1"; local name="\$2"
  if [ -d "\$d" ]; then
    echo "   \$name: ✅ Present" >> "\$REPORT_FILE"
  else
    echo "   \$name: ❌ Missing" >> "\$REPORT_FILE"
  fi
}
rate_dir "\$MEMORY_DIR" "Memory folder"
rate_dir "\$ARCH_DIR" "Archetypes modules folder"
if [ -n "\$ORCH_FILE" ]; then
  echo "   Orchestrator: ✅ Present" >> "\$REPORT_FILE"
else
  echo "   Orchestrator: ❌ Missing" >> "\$REPORT_FILE"
fi
if [ "\$AGENT_COUNT" -ge 15 ]; then
  echo "   Agent module count: ✅ \$AGENT_COUNT modules (>=15)" >> "\$REPORT_FILE"
else
  echo "   Agent module count: ⚠️ \$AGENT_COUNT modules (less than 15)" >> "\$REPORT_FILE"
fi
echo "" >> "\$REPORT_FILE"

# 8. Recommendations
echo "=== Recommendations ===" >> "\$REPORT_FILE"
echo "   1. If orchestrator is missing or minimal, build main routing and communication layer." >> "\$REPORT_FILE"
echo "   2. Ensure at least 15 archetype modules with distinct roles are defined." >> "\$REPORT_FILE"
echo "   3. Integrate vector memory persistence, reflection cycle and long-term memory summarization." >> "\$REPORT_FILE"
echo "   4. Add sandbox or dry-run mode flags for safety before live execution." >> "\$REPORT_FILE"
echo "   5. Write a minimal UI or CLI to monitor status, memory size, active agents." >> "\$REPORT_FILE"
echo "" >> "\$REPORT_FILE"

# 9. Final summary
echo "Analysis finished at $(date)" >> "$REPORT_FILE"
echo "Report saved to: $REPORT_FILE"
echo ""
echo "🔍 Please open $REPORT_FILE to review the detailed results, and we can work from there."
