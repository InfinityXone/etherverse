#!/usr/bin/env bash
set -euo pipefail

echo "🧹 [1/6] Cleaning and syncing Etherverse repository..."
cd ~/etherverse

# === PRE-CLEANING ===
echo "🧼 Removing junk, caches, temporary, and large unneeded files..."
find . -type f \( -name '*.log' -o -name '*.tmp' -o -name '*.bak' -o -name '*.swp' -o -name '*.DS_Store' -o -name '__pycache__' -o -name '*.pyc' \) -delete
rm -rf .pytest_cache/ .cache/ node_modules/ dist/ build/ tmp/ __pycache__/ > /dev/null 2>&1 || true

# Optional: remove files larger than 100MB (GitHub won't accept them)
echo "⚠️ Checking for large files > 100MB..."
find . -type f -size +100M -exec echo "Removing large file: {}" \; -exec rm -f {} \;

# === GIT SETUP ===
echo "🔧 [2/6] Ensuring git is initialized..."
git init -q

echo "🔗 [3/6] Linking to remote InfinityXone/etherverse..."
git remote remove origin 2>/dev/null || true
git remote add origin https://github.com/InfinityXone/etherverse.git

# === COMMIT & PUSH ===
echo "📦 [4/6] Staging all files..."
git add .

echo "🧾 [5/6] Committing changes..."
git commit -m '🧠 Etherverse full sync – cleaned and optimized' || echo "⚠️ Nothing new to commit."

echo "🚀 [6/6] Pushing to remote..."
git branch -M main
git push -u origin main --force

echo "✅ Sync complete! Repository is live at:"
echo "   https://github.com/InfinityXone/etherverse"
