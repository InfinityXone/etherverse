#!/bin/bash
# =====================================================
# 🔍 Verify Etherverse GCP service account key validity
# =====================================================
KEY="$HOME/etherverse/credentials/etherverse-gcp-service-key.json"

echo ""
echo "🧩 Checking service key integrity..."
if [[ ! -f "$KEY" ]]; then
  echo "❌ No key found at $KEY"
  exit 1
fi

# 1. Confirm project matches
PID=$(grep '"project_id"' "$KEY" | head -1 | cut -d'"' -f4)
echo "🔗 Key project ID: $PID"
if [[ "$PID" != "etherverse" ]]; then
  echo "⚠️  Key belongs to different project ($PID) — should be 'etherverse'"
fi

# 2. Validate cryptographic signature by requesting an access token
echo "🔐 Testing key signature..."
python3 - <<'PY'
import os, sys
from google.oauth2 import service_account
from google.auth.transport.requests import Request
cred_file = os.path.expanduser("~/etherverse/credentials/etherverse-gcp-service-key.json")
try:
    creds = service_account.Credentials.from_service_account_file(
        cred_file, scopes=["https://www.googleapis.com/auth/cloud-platform"]
    )
    creds.refresh(Request())
    print(f"✅ Valid key: token expires {creds.expiry}")
except Exception as e:
    print("❌ Invalid key or signature:", e)
PY
echo ""
