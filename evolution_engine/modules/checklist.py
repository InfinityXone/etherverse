#!/usr/bin/env python3
import sqlite3, os, time

STATE_DB = os.path.expanduser("$STATE_DB")

def rate_system():
    conn = sqlite3.connect(STATE_DB)
    cur = conn.cursor()
    cur.execute("CREATE TABLE IF NOT EXISTS diagnostics(ts INTEGER, service TEXT, status TEXT)")
    rows = cur.execute("SELECT status FROM diagnostics ORDER BY ts DESC LIMIT 10").fetchall()
    conn.close()
    score = 100
    for (status,) in rows:
        if status != "active":
            score -= 5
    return max(score,0)

def main():
    score = rate_system()
    broken = []
    if score < 50:
        broken.append("Critical services down or unstable.")
    print(f"Checklist: score={score}")
    if broken:
        print("Broken items:")
        for b in broken:
            print(" -", b)

if __name__ == "__main__":
    main()
