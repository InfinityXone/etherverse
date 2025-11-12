#!/bin/bash
# ============================================================
# 🔐 Etherverse GCP Key Configurator — Interactive Installer
# ============================================================

CONFIG_DIR="$HOME/etherverse/credentials"
CONFIG_FILE="$CONFIG_DIR/gcp-service-key.json"
PROJECT_ID_EXPECTED="etherverse"

echo ""
echo "============================================================"
echo "   🔐 Etherverse GCP Interactive Key Configuration Wizard   "
echo "============================================================"
echo ""

mkdir -p "$CONFIG_DIR"

# --- Step 1: Choose input method ---
echo "How would you like to provide your Google Cloud service key?"
echo "1️⃣  Paste the JSON directly"
echo "2️⃣  Point to a local file (e.g., ~/Downloads/key.json)"
read -rp "Select an option [1 or 2]: " CHOICE

if [[ "$CHOICE" == "1" ]]; then
    echo ""
    echo "Paste your JSON key below. End input with CTRL+D when done:"
    cat > "$CONFIG_FILE"
elif [[ "$CHOICE" == "2" ]]; then
    read -rp "Enter full path to your JSON key file: " FILE_PATH
    if [[ -f "$FILE_PATH" ]]; then
        cp "$FILE_PATH" "$CONFIG_FILE"
    else
        echo "❌ File not found: $FILE_PATH"
        exit 1
    fi
else
    echo "❌ Invalid selection. Exiting."
    exit 1
fi

# --- Step 2: Validate JSON syntax ---
if ! jq empty "$CONFIG_FILE" >/dev/null 2>&1; then
    echo "❌ Invalid JSON format. Please check your key file."
    exit 1
fi
echo "✅ JSON format valid."

# --- Step 3: Verify project ID ---
PROJECT_ID=$(jq -r '.project_id' "$CONFIG_FILE")
if [[ "$PROJECT_ID" != "$PROJECT_ID_EXPECTED" ]]; then
    echo "⚠️  Project ID mismatch: $PROJECT_ID"
    read -rp "Would you like to continue anyway? [y/N]: " CONT
    if [[ "$CONT" != "y" && "$CONT" != "Y" ]]; then
        echo "🛑 Exiting without saving key."
        exit 1
    fi
else
    echo "✅ Project ID verified: $PROJECT_ID"
fi

# --- Step 4: Secure permissions ---
chmod 600 "$CONFIG_FILE"
echo "🔒 Permissions locked for: $CONFIG_FILE"

# --- Step 5: Confirm save ---
echo ""
echo "✅ Key saved successfully!"
echo "📁 Location: $CONFIG_FILE"
echo "------------------------------------------------------------"
echo "You can now test your key with:"
echo "   bash ~/etherverse/scripts/verify_gcp_key.sh"
echo "------------------------------------------------------------"
echo ""
