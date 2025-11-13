from fastapi import FastAPI
import sqlite3, datetime
app = FastAPI()

@app.post("/write")
def write(agent:str, event:str, content:str):
    conn = sqlite3.connect("memory_core/data/hive_local.db")
    conn.execute("INSERT INTO memories(agent,event,content,created_at) VALUES (?,?,?,?)",
                 (agent,event,content,datetime.datetime.utcnow().isoformat()))
    conn.commit(); conn.close()
    return {"status":"ok"}

@app.get("/query")
def query(agent:str):
    conn=sqlite3.connect("memory_core/data/hive_local.db")
    cur=conn.execute("SELECT event,content FROM memories WHERE agent=? ORDER BY id DESC LIMIT 10",(agent,))
    data=cur.fetchall(); conn.close(); return {"memories":data}
