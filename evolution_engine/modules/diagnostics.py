#!/usr/bin/env python3
import subprocess, json, sqlite3, os, time

STATE_DB = os.path.expanduser("$STATE_DB")

def check_service(svc):
    try:
        out = subprocess.check_output(["systemctl","is-active",svc], text=True).strip()
    except Exception:
        out = "unknown"
    return out

def main():
    services = ["etherverse-daemon.service","etherverse-auto-update.service"]
    results = {}
    for s in services:
        results[s] = check_service(s)
    print("Diagnostics:", json.dumps(results))
    conn = sqlite3.connect(STATE_DB)
    cur = conn.cursor()
    cur.execute("CREATE TABLE IF NOT EXISTS diagnostics(ts INTEGER, service TEXT, status TEXT)")
    ts = int(time.time())
    for svc, status in results.items():
        cur.execute("INSERT INTO diagnostics(ts, service, status) VALUES(?,?,?)", (ts, svc, status))
    conn.commit()
    conn.close()

if __name__ == "__main__":
    main()
