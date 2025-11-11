#!/usr/bin/env bash
# Etherverse → GitHub persistent sync
set -euo pipefail

REPO="$HOME/etherverse"
BRANCH="main"
TOKEN_FILE="$HOME/.github_pat"
REMOTE="https://github.com/InfinityXone/etherverse.git"

if [[ ! -f $TOKEN_FILE ]]; then
  echo "[ERR] No token file at $TOKEN_FILE"
  echo "Create it with:  echo 'ghp_xxx' > $TOKEN_FILE && chmod 600 $TOKEN_FILE"
  exit 1
fi
TOKEN=$(<"$TOKEN_FILE")

cd "$REPO"
git remote set-url origin "https://${TOKEN}@github.com/InfinityXone/etherverse.git"

echo "[↻] Pulling latest..."
git fetch origin "$BRANCH" && git reset --soft "origin/$BRANCH"

echo "[📦] Committing changes..."
git add -A
git diff --cached --quiet || git commit -m "🤖 AutoSync $(date '+%F %T')"

echo "[🚀] Pushing..."
git push origin "$BRANCH" --force
echo "[✅] Sync complete."
