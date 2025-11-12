#!/usr/bin/env bash
# ============================================================
# 🔐 Etherverse Interactive GCP Key Installer
# ============================================================

CRED_DIR="$HOME/etherverse/credentials"
DEST_KEY="$CRED_DIR/gcp-service-key.json"

echo "============================================================"
echo "🔐 Etherverse Interactive GCP Key Installer"
echo "============================================================"
echo ""
echo "This will safely store your new Google Cloud service account key."
echo "You can either paste the JSON content directly or provide the path to the file."
echo ""

mkdir -p "$CRED_DIR"

read -p "Would you like to (1) paste JSON or (2) provide file path? [1/2]: " mode

if [[ "$mode" == "1" ]]; then
    echo ""
    echo "🧩 Paste your full JSON key below, then press CTRL+D when finished:"
    echo "------------------------------------------------------------"
    tmpfile=$(mktemp)
    cat > "$tmpfile"
    echo "------------------------------------------------------------"
elif [[ "$mode" == "2" ]]; then
    read -p "📂 Enter full path to your JSON file (e.g. ~/Downloads/key.json): " filepath
    if [[ ! -f "$filepath" ]]; then
        echo "❌ File not found at: $filepath"
        exit 1
    fi
    tmpfile="$filepath"
else
    echo "❌ Invalid option."
    exit 1
fi

echo ""
echo "🔍 Validating JSON structure..."
if ! jq empty "$tmpfile" >/dev/null 2>&1; then
    echo "❌ Invalid JSON. Please check your key file."
    exit 1
fi
echo "✅ JSON format is valid."

project_id=$(jq -r '.project_id' "$tmpfile")

if [[ -z "$project_id" || "$project_id" == "null" ]]; then
    echo "❌ Could not find 'project_id' field in key."
    exit 1
fi

echo "🌐 Detected project ID: $project_id"
if [[ "$project_id" != "etherverse" ]]; then
    echo "⚠️ Warning: Project ID does not match 'etherverse'."
    read -p "Proceed anyway? [y/N]: " cont
    if [[ "$cont" != "y" ]]; then
        echo "Cancelled."
        exit 0
    fi
fi

cp "$tmpfile" "$DEST_KEY"
chmod 600 "$DEST_KEY"

echo ""
echo "✅ Key installed successfully."
echo "📁 Location: $DEST_KEY"
echo "🔒 Permissions set (600)"
echo ""
echo "------------------------------------------------------------"
echo "You can now verify with:"
echo "   bash ~/etherverse/scripts/verify_gcp_key.sh"
echo "------------------------------------------------------------"
