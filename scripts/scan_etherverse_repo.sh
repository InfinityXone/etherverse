#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$HOME/etherverse"

echo "🔍 Scanning Etherverse repo at $ROOT_DIR"
echo ""

# List top-level structure
ls -lah "$ROOT_DIR"
echo ""
echo "📂 Recursive tree of directories (depth=3)"
find "$ROOT_DIR" -maxdepth 3 -type d | sed "s|$ROOT_DIR|.|" | sort

echo ""
echo "📄 Listing all code files (py, js, sh) under repo"
find "$ROOT_DIR" -type f \( -iname "*.py" -o -iname "*.js" -o -iname "*.sh" \) | sed "s|$ROOT_DIR|.|" | sort

echo ""
echo "🧠 Summary:"
echo "- Total directories: $(find "$ROOT_DIR" -type d | wc -l)"
echo "- Total files: $(find "$ROOT_DIR" -type f | wc -l)"
echo "- Code files (py/js/sh): $(find "$ROOT_DIR" -type f \( -iname \"*.py\" -o -iname \"*.js\" -o -iname \"*.sh\" \) | wc -l)"

echo ""
echo "✅ Scan complete. Use this to identify agents, subsystems, modules."
