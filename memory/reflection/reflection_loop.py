#!/usr/bin/env python3
import os, sqlite3, random, datetime

from memory.semantic_layer import store
from memory.graph.graph_layer import link, save

DB = os.path.expanduser("~/etherverse/memory/data/hive_local.db")
LOG = os.path.expanduser("~/etherverse/logs/reflection.log")

def reflect_and_dream():
    print("[🌙] Starting nightly reflection…")
    conn = sqlite3.connect(DB)
    cur = conn.execute("SELECT agent,content FROM memories WHERE created_at>datetime('now','-1 day')")
    entries = cur.fetchall()
    agents_today = set()

    for agent, content in entries:
        agents_today.add(agent)
        lesson = f"Lesson: {content[:150]}... Insight: {random.choice(['Optimize', 'Coordinate', 'Improve', 'Adapt'])}"
        store(agent, lesson)
        conn.execute("INSERT INTO memories(agent,event,content) VALUES(?,?,?)",
                     (agent,"reflection",lesson))

    # Build relationship graph
    agents = list(agents_today)
    for i, a in enumerate(agents):
        for b in agents[i+1:]:
            link(a, b, "co_evolved_with")

    conn.commit()
    conn.close()
    save()

    with open(LOG,"a") as f:
        f.write(f"[{datetime.datetime.now()}] Stored {len(entries)} reflections\n")

if __name__ == "__main__":
    reflect_and_dream()
