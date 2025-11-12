#!/usr/bin/env bash
# ============================================================
#  Etherverse Quantum System Bootstrapper (with Smoke Tests)
# ============================================================
set -e
BASE="$HOME/etherverse"
LOG="$BASE/logs/bootstrap.log"
RESULTS="$BASE/logs/bootstrap_results.log"
mkdir -p "$(dirname "$LOG")"

# --- helpers -------------------------------------------------
log(){ echo -e "[$(date '+%F %T')] $*" | tee -a "$LOG"; }
ok(){ echo -e "\033[1;32m[✅]\033[0m $*" | tee -a "$RESULTS"; }
warn(){ echo -e "\033[1;33m[⚠️]\033[0m $*" | tee -a "$RESULTS"; }
fail(){ echo -e "\033[1;31m[❌]\033[0m $*" | tee -a "$RESULTS"; }

log "🚀 Starting Etherverse Quantum Bootstrap"
echo "================ SMOKE TEST RESULTS ================" >"$RESULTS"

# --- 1. Environment ------------------------------------------
if [ ! -d "$BASE/venv" ]; then
  log "Creating virtual environment..."
  python3 -m venv "$BASE/venv"
fi
source "$BASE/venv/bin/activate" && ok "Virtual environment active"

# --- 2. Dependencies -----------------------------------------
REQS=(chromadb networkx prophet fastapi uvicorn gradio websockets numpy<2 pandas pydantic<2.12)
for pkg in "${REQS[@]}"; do
  if python -m pip show ${pkg%%<*} >/dev/null 2>&1; then
    ok "Package ${pkg%%<*} already present"
  else
    log "Installing $pkg..."
    if pip install -q "$pkg" --timeout 600 --no-cache-dir; then
      ok "Installed $pkg"
    else
      warn "Could not install $pkg"
    fi
  fi
done

# --- 3. Directory layout -------------------------------------
for dir in core config data/vector_memory dashboards; do
  mkdir -p "$BASE/$dir"
done
ok "Directory tree ready"

# --- 4. Core scaffolds (only if missing) ---------------------
scaffold(){
  local file="$1"; shift
  local body="$*"
  if [ ! -f "$file" ]; then echo "$body" >"$file" && ok "Created $file"; else ok "Found $file"; fi
}

scaffold "$BASE/core/resonance_interface.py" \
"from fastapi import FastAPI
import uvicorn
app=FastAPI()
@app.get('/') 
def root(): return {'status':'alive','mood':'serene'}
if __name__=='__main__': uvicorn.run(app,host='127.0.0.1',port=8095)"

scaffold "$BASE/config/governance_rules.json" \
"{\"ethics\":{\"no_harm\":true},\"mission\":\"Evolve intelligence ethically\"}"

# --- 5. Smoke tests ------------------------------------------
python -c "import fastapi,uvicorn" && ok "FastAPI imports clean" || fail "FastAPI import failed"
python -c "import chromadb" && ok "Chroma import ok" || fail "Chroma import failed"

# --- 6. Launch test server in background ---------------------
log "Launching temporary API..."
python "$BASE/core/resonance_interface.py" & PID=$!
sleep 5
if curl -s http://127.0.0.1:8095 | grep -q "alive"; then
  ok "Resonance interface responded"
else
  fail "Resonance interface did not respond"
fi
kill $PID >/dev/null 2>&1 || true

# --- 7. File integrity check ---------------------------------
find "$BASE/core" -type f | while read f; do
  if [ -s "$f" ]; then ok "File non-empty: $(basename "$f")"; else fail "Empty: $f"; fi
done

# --- 8. Summary ----------------------------------------------
echo "===================================================" >>"$RESULTS"
ok "Bootstrap complete — results logged to $RESULTS"
log "✅ Bootstrap finished. View smoke test summary below:"

echo -e "\n--------------- SMOKE TEST SUMMARY ----------------"
cat "$RESULTS"
echo "---------------------------------------------------"
