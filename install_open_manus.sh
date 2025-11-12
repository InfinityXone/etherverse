#!/usr/bin/env bash
set -euo pipefail

# === Etherverse Open-Manus One-Shot Installer ===
# Builds a local multi-agent system with FastAPI backend and Next.js UI
# Requires sudo once for system packages

ROOT="$HOME/etherverse/open_manus"
PYENV="$ROOT/venv"
API="$ROOT/api"
UI="$ROOT/ui"

echo "[1/7] 🧱 Creating folders..."
mkdir -p "$API" "$UI" "$ROOT/logs" "$ROOT/playbooks"

echo "[2/7] 🧩 Installing system packages..."
sudo apt update -y
sudo apt install -y python3 python3-venv python3-pip nodejs npm git curl

echo "[3/7] 🧠 Setting up Python environment..."
python3 -m venv "$PYENV"
source "$PYENV/bin/activate"
pip install --upgrade pip wheel
pip install fastapi uvicorn[standard] httpx pydantic python-dotenv apscheduler chromadb

# === BACKEND ===
echo "[4/7] ✍️ Writing FastAPI backend..."
cat > "$API/main.py" <<'PY'
from fastapi import FastAPI, BackgroundTasks
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
import asyncio, json, datetime, sqlite3, os

app = FastAPI(title="Open Manus API", version="1.0")
DB = os.path.join(os.path.dirname(__file__), "memory.db")
os.makedirs(os.path.dirname(DB), exist_ok=True)

def ensure_db():
    with sqlite3.connect(DB) as c:
        c.execute("""CREATE TABLE IF NOT EXISTS memory(
                        id INTEGER PRIMARY KEY,
                        ts TEXT,
                        role TEXT,
                        content TEXT)""")
        c.commit()
ensure_db()

def log(role, content):
    with sqlite3.connect(DB) as c:
        c.execute("INSERT INTO memory(ts,role,content) VALUES(?,?,?)",
                  (datetime.datetime.utcnow().isoformat(), role, content))
        c.commit()

class Prompt(BaseModel):
    prompt: str

@app.get("/")
def root():
    return {"status": "ok", "message": "Open-Manus backend running"}

@app.get("/memory")
def memory(limit: int = 20):
    ensure_db()
    with sqlite3.connect(DB) as c:
        rows = c.execute("SELECT ts, role, content FROM memory ORDER BY id DESC LIMIT ?",
                         (limit,)).fetchall()
    return [{"ts": r[0], "role": r[1], "content": r[2]} for r in rows]

@app.post("/orchestrate")
async def orchestrate(data: Prompt, background: BackgroundTasks):
    background.add_task(run_cycle, data.prompt)
    return {"status": "started", "prompt": data.prompt}

async def run_cycle(prompt: str):
    log("user", prompt)
    for i in range(5):
        await asyncio.sleep(0.5)
        msg = f"Processing step {i+1} for: {prompt}"
        log("agent", msg)
    result = f"✅ Finished task: {prompt}"
    log("system", result)
    return

@app.get("/stream")
async def stream(prompt: str):
    async def event_stream():
        for i in range(5):
            await asyncio.sleep(0.5)
            yield f"data: step {i+1} processing {prompt}\n\n"
        yield f"data: done ✅\n\n"
    return StreamingResponse(event_stream(), media_type="text/event-stream")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8081)
PY

# === FRONTEND ===
echo "[5/7] 🖥️ Setting up Next.js UI..."
cd "$UI"
npm init -y
npm install next react react-dom tailwindcss postcss autoprefixer lucide-react
npx tailwindcss init -p

# Tailwind config
cat > tailwind.config.js <<'JS'
/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: 'class',
  content: ['./pages/**/*.{js,ts,jsx,tsx}', './components/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {},
  },
  plugins: [],
}
JS

# PostCSS config already created by init

# package.json update for scripts
npx json -I -f package.json -e 'this.scripts={"dev":"next dev","build":"next build","start":"next start"}'

mkdir -p pages components styles public

# globals.css
cat > styles/globals.css <<'CSS'
@tailwind base;
@tailwind components;
@tailwind utilities;

body {
  @apply bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100 transition-colors;
}
CSS

# _app.js
cat > pages/_app.js <<'JS'
import '@/styles/globals.css'
import { useState, useEffect } from 'react'

export default function App({ Component, pageProps }) {
  const [dark, setDark] = useState(false)
  useEffect(() => {
    document.documentElement.classList.toggle('dark', dark)
  }, [dark])
  return (
    <div className="min-h-screen flex flex-col">
      <header className="flex items-center justify-between px-4 py-2 bg-gray-200 dark:bg-gray-800">
        <h1 className="font-bold">Open-Manus Dashboard</h1>
        <button onClick={() => setDark(!dark)} className="px-2 py-1 rounded bg-gray-300 dark:bg-gray-700">
          {dark ? 'Light' : 'Dark'} mode
        </button>
      </header>
      <main className="flex-1 p-4">
        <Component {...pageProps} />
      </main>
    </div>
  )
}
JS

# index.js
cat > pages/index.js <<'JS'
import { useState } from 'react'

export default function Home() {
  const [prompt, setPrompt] = useState('')
  const [logs, setLogs] = useState([])
  const runTask = async () => {
    setLogs(l => [...l, { role:'user', content: prompt }])
    await fetch('http://localhost:8081/orchestrate', {
      method:'POST', headers:{'Content-Type':'application/json'},
      body: JSON.stringify({prompt})
    })
    const res = await fetch('http://localhost:8081/memory')
    const data = await res.json()
    setLogs(data)
  }
  return (
    <div className="max-w-2xl mx-auto">
      <textarea
        className="w-full border dark:border-gray-700 p-2 rounded bg-gray-50 dark:bg-gray-900"
        rows="4"
        placeholder="Describe your task..."
        value={prompt}
        onChange={e => setPrompt(e.target.value)}
      />
      <button onClick={runTask} className="mt-2 px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-500">
        Run
      </button>
      <div className="mt-6 space-y-2">
        {logs.map((l,i)=>(
          <div key={i} className="border dark:border-gray-700 rounded p-2">
            <b>{l.role}</b>: {l.content}
          </div>
        ))}
      </div>
    </div>
  )
}
JS

# next.config.js
cat > next.config.js <<'JS'
/** @type {import('next').NextConfig} */
const nextConfig = { reactStrictMode: true }
module.exports = nextConfig
JS

cd "$ROOT"

# === README ===
cat > "$ROOT/README.md" <<'MD'
# Open-Manus Local System
- FastAPI backend at **http://localhost:8081**
- Next.js UI at **http://localhost:3000**

## Run
```bash
source venv/bin/activate
python api/main.py
# new terminal
cd ui && npm run dev
