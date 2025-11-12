#!/usr/bin/env python3
import sqlite3, os, time

DB = os.path.expanduser("~/etherverse/evolution_engine/data/state.sqlite")

def fetch_scores(limit=10):
    conn = sqlite3.connect(DB)
    cur = conn.cursor()
    cur.execute("SELECT ts, metric, value FROM metrics ORDER BY ts DESC LIMIT ?", (limit,))
    rows = cur.fetchall()
    conn.close()
    return rows

def simple_forecast():
    rows = fetch_scores()
    bad_count = sum(1 for ts, metric, val in rows if val != 'active')
    if bad_count > len(rows)*0.3:
        return "Forecast: risk of system drift in next cycle."
    return "Forecast: system likely stable."

if __name__ == "__main__":
    print(simple_forecast())
