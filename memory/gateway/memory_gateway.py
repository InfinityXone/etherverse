from fastapi import FastAPI
import sqlite3, datetime, os

app = FastAPI()

DB = os.path.expanduser("~/etherverse/memory/data/hive_local.db")

@app.post("/write")
def write(agent:str, event:str, content:str):
    conn = sqlite3.connect(DB)
    conn.execute(
      "INSERT INTO memories(agent,event,content,created_at) VALUES(?,?,?,?)",
      (agent,event,content,datetime.datetime.utcnow().isoformat())
    )
    conn.commit()
    conn.close()
    return {"status":"ok"}

@app.get("/query")
def query(agent:str):
    conn = sqlite3.connect(DB)
    cur = conn.execute("SELECT event,content FROM memories WHERE agent=? ORDER BY id DESC LIMIT 20",(agent,))
    out = cur.fetchall()
    conn.close()
    return {"memories":out}
