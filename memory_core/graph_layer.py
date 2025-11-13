import networkx as nx, os, json

GRAPH_PATH = os.path.expanduser("~/etherverse/memory_core/data/hive_graph.json")
G = nx.DiGraph()

# load existing graph
if os.path.exists(GRAPH_PATH):
    with open(GRAPH_PATH) as f:
        G.add_edges_from(json.load(f))

def link(a,b,rel="connects_to"):
    G.add_edge(a,b,relation=rel)
    save()

def related(node):
    return [(b,G[a][b]["relation"]) for a,b in G.edges(node)]

def save():
    with open(GRAPH_PATH,"w") as f:
        json.dump([(a,b,G[a][b]["relation"]) for a,b in G.edges],f)

def visualize():
    import matplotlib.pyplot as plt
    pos=nx.spring_layout(G)
    nx.draw(G,pos,with_labels=True,node_color="lightblue",font_size=8)
    nx.draw_networkx_edge_labels(G,pos,edge_labels={(a,b):d['relation'] for a,b,d in G.edges(data=True)})
    plt.show()
