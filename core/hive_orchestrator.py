from fastapi import FastAPI

app = FastAPI(title="Etherverse Hive Orchestrator")

@app.get("/")
def root():
    return {"status": "alive", "message": "Hive Orchestrator responding"}
