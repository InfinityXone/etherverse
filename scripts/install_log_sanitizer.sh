#!/bin/bash
# ============================================================
# 🧹 Etherverse Log Sanitizer Installer
# ============================================================
# Automatically removes tokens, secrets, and API keys from logs
# before any sync or Git commit operations.
# ============================================================

TARGET_DIR="$HOME/etherverse/logs"
PATCH_SCRIPT="$HOME/etherverse/scripts/sanitize_logs.sh"

mkdir -p "$HOME/etherverse/scripts"

cat <<'EOF' > "$PATCH_SCRIPT"
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
EOF

chmod +x "$PATCH_SCRIPT"

# Add auto-hook for sanitization before commits
HOOK_FILE="$HOME/etherverse/.git/hooks/pre-commit"
cat <<'EOF' > "$HOOK_FILE"
#!/bin/bash
# 🧠 Etherverse Git Pre-Commit Log Sanitizer Hook
$HOME/etherverse/scripts/sanitize_logs.sh
EOF

chmod +x "$HOOK_FILE"

echo "[✅] Sanitizer hook installed. All future commits will auto-clean logs."
