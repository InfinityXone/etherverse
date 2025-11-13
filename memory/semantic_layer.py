from langchain.embeddings import HuggingFaceEmbeddings
import chromadb, os

CHROMA_PATH = os.path.expanduser("~/etherverse/memory/chroma")
client = chromadb.PersistentClient(path=CHROMA_PATH)
collection = client.get_or_create_collection("hive_semantic")

embedder = HuggingFaceEmbeddings(model_name="sentence-transformers/all-MiniLM-L6-v2")

def store(agent, text):
    vec = embedder.embed_query(text)
    collection.add(
        documents=[text],
        metadatas=[{"agent": agent}],
        ids=[str(hash(text))]
    )

def search(query, k=5):
    qv = embedder.embed_query(query)
    res = collection.query(query_embeddings=[qv], n_results=k)
    return res["documents"][0]
