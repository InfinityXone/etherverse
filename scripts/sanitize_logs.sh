#!/bin/bash
LOG_DIR="$HOME/etherverse/logs"
SAFE_LOG_DIR="$HOME/etherverse/logs/safe"

mkdir -p "$SAFE_LOG_DIR"

echo "[🧼] Sanitizing logs in: $LOG_DIR"

# Remove sensitive patterns
for file in $(find "$LOG_DIR" -type f -name "*.log"); do
    safe_file="$SAFE_LOG_DIR/$(basename "$file")"
    grep -Ev 'ghp_|github_pat_|token=|apikey=|Authorization:|Bearer ' "$file" > "$safe_file"
done

# Replace originals with sanitized versions
cp -f "$SAFE_LOG_DIR"/*.log "$LOG_DIR"/ 2>/dev/null
echo "[✅] Logs sanitized and replaced safely."
