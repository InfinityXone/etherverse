#!/usr/bin/env bash
# ============================================================
# Etherverse Quantum Health Runner
# ============================================================
set -e
BASE="$HOME/etherverse"
LOG="$BASE/logs/quantum_health.log"

echo "[🩺 $(date)] Running Etherverse Quantum Health check" | tee -a "$LOG"

# --- Main checks ---
if [ -f "$BASE/scripts/bootstrap_quantum_system.sh" ]; then
    bash "$BASE/scripts/bootstrap_quantum_system.sh" >>"$LOG" 2>&1 || echo "[⚠️] Bootstrap failed" >>"$LOG"
else
    echo "[❌] Missing bootstrap_quantum_system.sh" | tee -a "$LOG"
fi

if [ -f "$BASE/scripts/upgrade_quantum_self_audit.sh" ]; then
    bash "$BASE/scripts/upgrade_quantum_self_audit.sh" >>"$LOG" 2>&1 || echo "[⚠️] Audit failed" >>"$LOG"
else
    echo "[❌] Missing upgrade_quantum_self_audit.sh" | tee -a "$LOG"
fi

# --- Ledger update ---
mkdir -p "$BASE/docs"
echo "---" >>"$BASE/docs/consciousness_ledger.md"
tail -n 20 "$LOG" >>"$BASE/docs/consciousness_ledger.md"

# --- Auto Git commit and push ---
cd "$BASE"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[🌐] Syncing latest logs and ledger to GitHub..." | tee -a "$LOG"
  git add docs logs || true
  git commit -m "🩺 Auto health sync: $(date '+%Y-%m-%d %H:%M')" || true
  git push origin main --quiet || echo "[⚠️] Git push failed" | tee -a "$LOG"
else
  echo "[⚠️] No Git repo found in $BASE" | tee -a "$LOG"
fi

echo "[✅] Health check complete." | tee -a "$LOG"
