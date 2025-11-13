#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$HOME/etherverse"
REMOTE_URL="https://github.com/InfinityXone/etherverse.git"

echo "[🔧] Pushing $REPO_DIR to $REMOTE_URL"

if [ ! -d "$REPO_DIR" ]; then
  echo "[❌] Directory $REPO_DIR does not exist."
  exit 1
fi

cd "$REPO_DIR"

# Initialize git repo if needed
if [ ! -d ".git" ]; then
  echo "[🧬] Initializing new git repository..."
  git init
fi

# Ensure main branch
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD || echo '')"
if [ "$CURRENT_BRANCH" = "HEAD" ] || [ -z "$CURRENT_BRANCH" ]; then
  git checkout -b main || git branch -M main
else
  git branch -M main
fi

# Create a sane .gitignore if it does not exist
if [ ! -f .gitignore ]; then
  echo "[📜] Creating .gitignore..."
  cat << 'EOF' > .gitignore
# Python
__pycache__/
*.py[cod]
*.pyo
*.pyd
*.so
*.egg-info/

# Virtual envs
venv/
.venv/
env/
.env/

# Node / JS
node_modules/
dist/
.build/
.next/

# Logs & temp
logs/
*.log
*.tmp
*.swp

# OS / editor junk
.DS_Store
Thumbs.db
.idea/
.vscode/

# Databases / cache
*.sqlite3
*.db
.cache/
EOF
fi

echo "[➕] Staging files..."
git add .

# Commit only if there are changes
if ! git diff --cached --quiet; then
  echo "[✅] Committing changes..."
  git commit -m "chore: sync local etherverse to GitHub" || true
else
  echo "[ℹ️] No changes to commit."
fi

# Configure remote
if git remote get-url origin >/dev/null 2>&1; then
  echo "[🌐] Updating origin remote URL..."
  git remote set-url origin "$REMOTE_URL"
else
  echo "[🌐] Adding origin remote..."
  git remote add origin "$REMOTE_URL"
fi

echo "[📤] Pushing to GitHub (main)..."
git push -u origin main

echo "[🎉] Done. Local ~/etherverse is synced to InfinityXone/etherverse."
