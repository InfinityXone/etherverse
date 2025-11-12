#!/usr/bin/env python3
import sqlite3, os

DB = os.path.expanduser("~/etherverse/evolution_engine/data/state.sqlite")

def fetch_recent_scores(limit=5):
    conn = sqlite3.connect(DB)
    cur = conn.cursor()
    cur.execute("SELECT ts, metric, value FROM metrics ORDER BY ts DESC LIMIT ?", (limit,))
    rows = cur.fetchall()
    conn.close()
    return rows

def generate_recommendations():
    recent = fetch_recent_scores()
    recs = []
    for ts, metric, value in recent:
        if 'etherverse-auto-update.service' in metric and value != 'active':
            recs.append("Enable or repair auto-update service.")
    if not recs:
        recs.append("System operating within defined thresholds.")
    return recs

if __name__ == "__main__":
    recs = generate_recommendations()
    print("Recommendations:")
    for r in recs:
        print(" -", r)
