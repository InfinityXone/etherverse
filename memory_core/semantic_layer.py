from langchain.embeddings import HuggingFaceEmbeddings
import chromadb, os, json

CHROMA_PATH = os.path.expanduser("~/etherverse/memory_core/chroma")
client = chromadb.PersistentClient(path=CHROMA_PATH)
collection = client.get_or_create_collection("hive_semantic")

embedder = HuggingFaceEmbeddings(model_name="sentence-transformers/all-MiniLM-L6-v2")

def store(agent, text):
    vec = embedder.embed_query(text)
    collection.add(documents=[text], metadatas=[{"agent":agent}], ids=[str(hash(text))])

def search(query, k=5):
    vec = embedder.embed_query(query)
    res = collection.query(query_embeddings=[vec], n_results=k)
    return [r for r in zip(res["documents"][0], res["metadatas"][0])]
