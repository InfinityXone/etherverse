#!/usr/bin/env python3
"""
🌙 Etherverse Reflection & Dream Loop v2
Generates daily lessons, semantic embeddings,
and inter-agent relationship updates.
"""
import os, sqlite3, random, datetime, json
from memory_core.semantic_layer import store
from memory_core.graph_layer import link, save

DB = os.path.expanduser("~/etherverse/memory_core/data/hive_local.db")
LOG = os.path.expanduser("~/etherverse/logs/dream.log")

def reflect_and_dream():
    print("[🌙] Starting nightly reflection & graph learning…")
    conn = sqlite3.connect(DB)
    cur = conn.execute(
        "SELECT agent,content FROM memories WHERE created_at>datetime('now','-1 day')"
    )
    entries = cur.fetchall()
    agents_today = set()
    for agent, content in entries:
        agents_today.add(agent)
        lesson = (
            f"Lesson: {content[:200]}..."
            f" Insight: {random.choice(['Collaborate better','Adapt faster','Improve ethics','Optimize process'])}"
        )
        store(agent, lesson)
        conn.execute(
            "INSERT INTO memories(agent,event,content) VALUES(?,?,?)",
            (agent, "reflection", lesson),
        )

    # Create relationship links between active agents
    agents = list(agents_today)
    for i, a in enumerate(agents):
        for b in agents[i + 1 :]:
            link(a, b, "co_evolved_with")

    conn.commit()
    conn.close()
    save()
    with open(LOG, "a") as f:
        f.write(f"[{datetime.datetime.now()}] Dream reflections complete — {len(entries)} entries.\n")
    print(f"[✅] Reflections and graph updated ({len(entries)} memories).")

if __name__ == "__main__":
    reflect_and_dream()
