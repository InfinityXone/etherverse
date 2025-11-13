#!/usr/bin/env python3
"""
🌐 Hive Graph Cognition Layer (NetworkX Edition)
------------------------------------------------
Lightweight, modular, agent-to-agent relationship engine.
Stores all links in JSON and optionally exports a PNG graph
for visualization on headless systems (Chromebook).
"""

import networkx as nx
import os, json

# Where graph data is stored (persistent on Drive)
GRAPH_PATH = os.path.expanduser("~/etherverse/memory_core/data/hive_graph.json")

# Initialize global directed graph
G = nx.DiGraph()

# Load existing graph file if present
if os.path.exists(GRAPH_PATH):
    try:
        with open(GRAPH_PATH) as f:
            edges = json.load(f)
            for a, b, rel in edges:
                G.add_edge(a, b, relation=rel)
        print("[🧠] Hive graph loaded from disk.")
    except Exception as e:
        print("[⚠️] Failed to load graph file:", e)


# ----------------------------
# Add links (relationships)
# ----------------------------
def link(a, b, relation="connected_to"):
    """
    Add a relationship: a --relation--> b
    """
    G.add_edge(a, b, relation=relation)
    save()


# ----------------------------
# Query relationships
# ----------------------------
def related(entity):
    """
    Return all outgoing edges for a given entity.
    """
    if entity not in G:
        return []
    return [(b, G[entity][b]["relation"]) for b in G.successors(entity)]


# ----------------------------
# Save graph to disk
# ----------------------------
def save():
    data = []
    for a, b in G.edges:
        data.append([a, b, G[a][b]["relation"]])
    os.makedirs(os.path.dirname(GRAPH_PATH), exist_ok=True)
    with open(GRAPH_PATH, "w") as f:
        json.dump(data, f, indent=2)


# ----------------------------
# Visualize graph to PNG
# ----------------------------
def visualize(output=None):
    """
    Export current hive graph to a PNG (headless friendly)
    Default location: ~/etherverse/logs/hive_graph.png
    """
    import matplotlib
    matplotlib.use("Agg")  # Headless backend
    import matplotlib.pyplot as plt

    if not output:
        output = os.path.expanduser("~/etherverse/logs/hive_graph.png")

    pos = nx.spring_layout(G, seed=42)

    plt.figure(figsize=(10, 8))
    nx.draw(
        G,
        pos,
        with_labels=True,
        node_color="skyblue",
        node_size=2000,
        font_size=9,
        edgecolors="gray",
        linewidths=1.2
    )

    nx.draw_networkx_edge_labels(
        G,
        pos,
        edge_labels={(a, b): d["relation"] for a, b, d in G.edges(data=True)},
        font_color="darkgreen",
        font_size=8
    )

    os.makedirs(os.path.dirname(output), exist_ok=True)
    plt.tight_layout()
    plt.savefig(output, dpi=220)
    plt.close()

    print(f"[📊] Hive graph exported → {output}")
