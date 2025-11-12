#!/usr/bin/env python3
# ============================================================
# 📤 Etherverse Autonomous Memory → Google Sheets (Safe + Reflection)
# ============================================================
import os, csv, time, re
import pandas as pd
from google.oauth2 import service_account
from googleapiclient.discovery import build

# --- Paths
ROOT = os.path.expanduser("~/etherverse")
CRED_FILE = os.path.join(ROOT, "credentials", "etherverse-gcp-service-key.json")
LOGS_DIR = os.path.join(ROOT, "logs")

# --- Locate newest memory CSV
csv_files = [os.path.join(LOGS_DIR, f) for f in os.listdir(LOGS_DIR)
             if f.startswith("memory_assets_export_") and f.endswith(".csv")]
if not csv_files:
    raise SystemExit("[❌] No memory_assets_export_*.csv found.")
CSV_FILE = sorted(csv_files, key=os.path.getmtime)[-1]
print(f"[📂] Uploading sanitized CSV: {CSV_FILE}")

# --- Clean + normalize the CSV
clean_file = os.path.join(LOGS_DIR, "memory_assets_clean.csv")
with open(CSV_FILE, "r", errors="ignore") as src, open(clean_file, "w", newline="") as out:
    writer = csv.writer(out)
    for raw in src:
        # Strip control chars / excessive commas
        line = re.sub(r'[\r\n]+', '', raw)
        parts = [p.strip('" ') for p in line.split(",") if p.strip()]
        if len(parts) < 3:
            parts += [""] * (3 - len(parts))
        writer.writerow(parts[:3])
CSV_FILE = clean_file

# --- Safe parse
df = pd.read_csv(CSV_FILE, on_bad_lines="skip", names=["timestamp","path","type"], header=0)
values = [df.columns.tolist()] + df.fillna("").values.tolist()

# --- Auth
SCOPES = ["https://www.googleapis.com/auth/spreadsheets"]
creds = service_account.Credentials.from_service_account_file(CRED_FILE, scopes=SCOPES)
sheets = build("sheets", "v4", credentials=creds)

# --- Create a new spreadsheet
sheet_title = f"Etherverse_Memory_{time.strftime('%Y%m%d_%H%M')}"
spreadsheet = sheets.spreadsheets().create(body={"properties": {"title": sheet_title}}).execute()
sheet_id = spreadsheet["spreadsheetId"]
print(f"[✅] Created Sheet: {sheet_title}")
print(f"[🔗] https://docs.google.com/spreadsheets/d/{sheet_id}/edit")

# --- Upload memory sheet
sheets.spreadsheets().values().update(
    spreadsheetId=sheet_id,
    range="A1",
    valueInputOption="RAW",
    body={"values": values}
).execute()
print("[📤] Memory data uploaded successfully.")

# --- Optional Hive Reflection Summary
reflect_files = [os.path.join(LOGS_DIR, f) for f in os.listdir(LOGS_DIR)
                 if f.startswith("hive_reflection_summary_") and f.endswith(".csv")]
if reflect_files:
    REFLECT_FILE = sorted(reflect_files, key=os.path.getmtime)[-1]
    print(f"[🌅] Adding Hive Reflection Summary: {REFLECT_FILE}")
    with open(REFLECT_FILE) as rf:
        reflection_data = list(csv.reader(rf))
    # create new sheet tab
    add_sheet_req = {"requests": [{"addSheet": {"properties": {"title": "Hive_Reflections"}}}]}
    sheets.spreadsheets().batchUpdate(spreadsheetId=sheet_id, body=add_sheet_req).execute()
    sheets.spreadsheets().values().update(
        spreadsheetId=sheet_id,
        range="Hive_Reflections!A1",
        valueInputOption="RAW",
        body={"values": reflection_data}
    ).execute()
    print("[✨] Hive Reflection Summary uploaded.")

print(f"[🏁] Done. View → https://docs.google.com/spreadsheets/d/{sheet_id}/edit")
