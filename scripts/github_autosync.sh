#!/usr/bin/env bash
# ==========================================================
#  Etherverse GitHub AutoSync Script
#  Maintains continuous sync to InfinityXone/etherverse repo
# ==========================================================

set -euo pipefail

REPO_DIR="$HOME/etherverse"
REPO_URL="https://github.com/InfinityXone/etherverse.git"
TOKEN_FILE="$HOME/.github_pat"
BRANCH="main"

# --- 1. Verify token exists ---
if [[ ! -f "$TOKEN_FILE" ]]; then
  echo "[ERR] Token file not found at $TOKEN_FILE"
  echo "Create it with:  echo 'ghp_yourPAT' > $TOKEN_FILE && chmod 600 $TOKEN_FILE"
  exit 1
fi

TOKEN=$(cat "$TOKEN_FILE")

# --- 2. Ensure correct Git remote configuration ---
cd "$REPO_DIR"
git remote set-url origin "https://${TOKEN}@github.com/InfinityXone/etherverse.git"

# --- 3. Pull latest changes ---
echo "[↻] Pulling latest from origin/$BRANCH..."
git fetch origin "$BRANCH"
git reset --soft "origin/$BRANCH"

# --- 4. Add, commit, push ---
echo "[📦] Committing local changes..."
git add -A
if git diff --cached --quiet; then
  echo "[✓] No new changes to commit."
else
  git commit -m "🤖 AutoSync: $(date '+%Y-%m-%d %H:%M:%S')"
fi

echo "[🚀] Pushing to remote..."
git push origin "$BRANCH" --force
echo "[✅] Sync complete!"
