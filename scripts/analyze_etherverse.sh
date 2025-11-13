#!/bin/bash

# ===========================================================
# ETHERVERSE SYSTEM ANALYSIS ENGINE
# Scans ALL frameworks, agents, LLM tools, configs, scripts,
# memory systems, front-end code, systemd units, cron jobs,
# AI infra, logs, and architecture.
# Output → ~/etherverse/logs/system_analysis/
# ===========================================================

ROOT_DIR="$HOME/etherverse"
OUT_DIR="$ROOT_DIR/logs/system_analysis"
mkdir -p "$OUT_DIR"

echo "[🔍] Etherverse Analysis Started..."
echo "[📁] Output directory: $OUT_DIR"


# -----------------------------------------------------------
# 1. Full filesystem tree
# -----------------------------------------------------------
echo "[1/6] Generating filesystem tree..."
tree -a -I "__pycache__|venv|node_modules|.git" "$ROOT_DIR" \
    > "$OUT_DIR/filesystem_tree.txt" 2>/dev/null


# -----------------------------------------------------------
# 2. Framework / LLM Stack Detection
# -----------------------------------------------------------
echo "[2/6] Detecting AI frameworks, LLM tools, and libs..."
{
    echo "=== PYTHON PACKAGES FOUND ==="
    pip list 2>/dev/null

    echo ""
    echo "=== FRAMEWORK DIRECTORIES DETECTED ==="
    find "$ROOT_DIR" -maxdepth 4 -type d | grep -Ei "torch|transformers|langchain|llama|ollama|superagi|crew|autogen|openai|groq|chromadb|mem0"

    echo ""
    echo "=== EXECUTABLES ON SYSTEM ==="
    which ollama 2>/dev/null
    which node 2>/dev/null
    which python 2>/dev/null
    which deno 2>/dev/null
    which uvicorn 2>/dev/null

} > "$OUT_DIR/framework_scan.txt"


# -----------------------------------------------------------
# 3. Agents + Manifests + Blueprints
# -----------------------------------------------------------
echo "[3/6] Scanning agents and manifests..."
{
    echo "=== AGENT DIRECTORIES ==="
    find "$ROOT_DIR" -maxdepth 4 -type d -iname "*agent*"

    echo ""
    echo "=== MANIFEST FILES ==="
    find "$ROOT_DIR" -type f -iname "*manifest*.json"

    echo ""
    echo "=== BLUEPRINTS ==="
    find "$ROOT_DIR" -type f -iname "*blueprint*.json" -o -iname "*blueprint*.md"

} > "$OUT_DIR/agent_registry_scan.txt"


# -----------------------------------------------------------
# 4. Configs, Infra, Credentials, Endpoints
# -----------------------------------------------------------
echo "[4/6] Scanning config & infrastructure..."
{
    echo "=== ENV FILES ==="
    find "$ROOT_DIR" -type f -iname "*.env"

    echo ""
    echo "=== JSON / YAML / TOML CONFIG ==="
    find "$ROOT_DIR" -type f \( -iname "*.json" -o -iname "*.yaml" -o -iname "*.yml" -o -iname "*.toml" \)

    echo ""
    echo "=== SYSTEMD UNITS RELATED TO ETHERVERSE ==="
    systemctl list-units --all | grep -Ei "etherverse|codex|helix|quantum|daemon" || echo "none found"

    echo ""
    echo "=== CRON JOBS ==="
    crontab -l 2>/dev/null || echo "no cron jobs"

    echo ""
    echo "=== PORT SCAN (LOCAL SERVICES) ==="
    ss -tulpn | grep -Ei "python|node|uvicorn|fastapi|flask|7777|8000"

    echo ""
    echo "=== CREDENTIAL FILES (keys/tokens) ==="
    find "$ROOT_DIR" -type f -iname "*key*.json" -o -iname "*credentials*.json"

} > "$OUT_DIR/config_and_infra.txt"


# -----------------------------------------------------------
# 5. Front-end + UI + API files
# -----------------------------------------------------------
echo "[5/6] Detecting front-end frameworks..."
{
    echo "=== NODE PROJECTS ==="
    find "$ROOT_DIR" -maxdepth 4 -type f -name "package.json"

    echo ""
    echo "=== NEXT.JS / REACT / TAILWIND DETECTION ==="
    find "$ROOT_DIR" -type f -iname "next.config.js"
    find "$ROOT_DIR" -type f -iname "tailwind.config.js"
    find "$ROOT_DIR" -type f -iname "*.tsx" -o -iname "*.jsx"

    echo ""
    echo "=== API ROUTES (Python / Node) ==="
    find "$ROOT_DIR" -type f -iname "*api*.py" -o -iname "*api*.js"

} > "$OUT_DIR/frontend_and_llm_stack.txt"


# -----------------------------------------------------------
# 6. Code Inventory (Python, JS, TS, Bash, HTML, etc)
# -----------------------------------------------------------
echo "[6/6] Creating code inventory..."
{
    echo "=== PYTHON ==="
    find "$ROOT_DIR" -type f -iname "*.py"

    echo ""
    echo "=== JAVASCRIPT / TYPESCRIPT ==="
    find "$ROOT_DIR" -type f -iname "*.js" -o -iname "*.ts"

    echo ""
    echo "=== SHELL SCRIPTS ==="
    find "$ROOT_DIR" -type f -iname "*.sh"

    echo ""
    echo "=== HTML/CSS ==="
    find "$ROOT_DIR" -type f -iname "*.html" -o -iname "*.css"

} > "$OUT_DIR/code_inventory.txt"


echo "[✅] Etherverse System Analysis Completed!"
echo "[📂] Reports stored in: $OUT_DIR"
