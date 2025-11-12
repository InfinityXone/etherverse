#!/usr/bin/env python3
import sqlite3, time, os, subprocess

DB_PATH = os.path.expanduser("$MODULE/data/state.sqlite")

def init_db():
    conn = sqlite3.connect(DB_PATH)
    conn.execute("CREATE TABLE IF NOT EXISTS metrics(ts INTEGER, metric TEXT, value TEXT)")
    conn.commit()
    conn.close()

def record(metric, value):
    conn = sqlite3.connect(DB_PATH)
    conn.execute("INSERT INTO metrics(ts, metric, value) VALUES (?, ?, ?)",
                 (int(time.time()), metric, str(value)))
    conn.commit()
    conn.close()

def check_services():
    svcs = ["etherverse-daemon.service","etherverse-auto-update.service"]
    results = {}
    for s in svcs:
        try:
            status = subprocess.check_output(["systemctl","is-active",s], text=True).strip()
        except Exception:
            status = "unknown"
        results[s] = status
    return results

if __name__ == \"__main__\":
    init_db()
    res = check_services()
    for svc, st in res.items():
        record(svc, st)
    print("Diagnostics module ran successfully:", res)
