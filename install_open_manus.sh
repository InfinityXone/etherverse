#!/usr/bin/env bash
set -euo pipefail

# === Open-Manus Bootstrap ===
# builds FastAPI backend + Next.js frontend on localhost
ROOT="$HOME/open_manus"
PY="$ROOT/venv"
API="$ROOT/api"
UI="$ROOT/ui"

echo "[1/7] 🧱 folders"
mkdir -p "$API" "$UI" "$ROOT/logs"

echo "[2/7] 🧩 base packages"
sudo apt update -y
sudo apt install -y python3 python3-venv python3-pip nodejs npm git curl

echo "[3/7] 🧠 python env"
python3 -m venv "$PY"
source "$PY/bin/activate"
pip install --upgrade pip wheel
pip install fastapi uvicorn[standard] httpx pydantic python-dotenv

echo "[4/7] ✍️ backend"
cat >"$API/main.py"<<'PY'
from fastapi import FastAPI, BackgroundTasks
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
import asyncio, datetime

app = FastAPI(title="Open-Manus API")

class Prompt(BaseModel):
    prompt: str

@app.get("/")
def root(): return {"status":"ok","msg":"backend running"}

@app.post("/orchestrate")
async def orchestrate(data:Prompt, background:BackgroundTasks):
    async def worker():
        await asyncio.sleep(1)
        print(f"[{datetime.datetime.now()}] task: {data.prompt}")
    background.add_task(worker)
    return {"status":"started","prompt":data.prompt}

@app.get("/stream")
async def stream(prompt:str):
    async def gen():
        for i in range(5):
            await asyncio.sleep(0.5)
            yield f"data: step {i+1} processing {prompt}\n\n"
        yield "data: done ✅\n\n"
    return StreamingResponse(gen(), media_type="text/event-stream")

if __name__=="__main__":
    import uvicorn; uvicorn.run(app,host="0.0.0.0",port=8081)
PY

echo "[5/7] 🖥 frontend"
cd "$UI"
npm init -y
npm install next react react-dom tailwindcss postcss autoprefixer lucide-react
npx tailwindcss init -p
cat >tailwind.config.js<<'JS'
module.exports={darkMode:'class',content:['./pages/**/*.{js,ts,jsx,tsx}','./components/**/*.{js,ts,jsx,tsx}'],theme:{extend:{}},plugins:[]}
JS
mkdir -p pages components styles
cat >styles/globals.css<<'CSS'
@tailwind base;@tailwind components;@tailwind utilities;
body{@apply bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100;}
CSS
cat >pages/_app.js<<'JS'
import '@/styles/globals.css'
import {useState,useEffect} from'react'
export default function App({Component,pageProps}){
 const [dark,setDark]=useState(false)
 useEffect(()=>{document.documentElement.classList.toggle('dark',dark)},[dark])
 return(<div className="min-h-screen flex flex-col">
  <header className="flex items-center justify-between px-4 py-2 bg-gray-200 dark:bg-gray-800">
   <h1 className="font-bold">Open-Manus</h1>
   <button onClick={()=>setDark(!dark)} className="px-2 py-1 rounded bg-gray-300 dark:bg-gray-700">
     {dark?'Light':'Dark'} mode
   </button>
  </header>
  <main className="flex-1 p-4"><Component {...pageProps}/></main>
 </div>)}
JS
cat >pages/index.js<<'JS'
import {useState} from'react'
export default function Home(){
 const[prompt,setPrompt]=useState('');const[logs,setLogs]=useState([]);
 async function run(){
  const res=await fetch('http://localhost:8081/orchestrate',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({prompt})});
  const mem=await fetch('http://localhost:8081/stream?prompt='+encodeURIComponent(prompt));
  const reader=mem.body.getReader();const dec=new TextDecoder();
  let done=false;let buf='';
  while(!done){const{value,done:d}=await reader.read();done=d;if(value)buf+=dec.decode(value);}
  setLogs(l=>[...l,{role:'system',content:buf}]);
 }
 return(<div className="max-w-2xl mx-auto">
  <textarea className="w-full border dark:border-gray-700 p-2 rounded bg-gray-50 dark:bg-gray-900"
   rows="4" placeholder="Type your request..." value={prompt} onChange={e=>setPrompt(e.target.value)}/>
  <button onClick={run} className="mt-2 px-4 py-2 bg-blue-600 text-white rounded">Run</button>
  <div className="mt-6 space-y-2">
   {logs.map((l,i)=>(<div key={i} className="border dark:border-gray-700 rounded p-2"><b>{l.role}</b>: {l.content}</div>))}
  </div>
 </div>)}
JS
cat >next.config.js<<'JS'
const nextConfig={reactStrictMode:true};module.exports=nextConfig;
JS
cd "$ROOT"

echo "[6/7] 🧭 start script"
cat >"$ROOT/start_all.sh"<<'BASH'
#!/usr/bin/env bash
ROOT="$HOME/open_manus"
source "$ROOT/venv/bin/activate"
uvicorn api.main:app --host 0.0.0.0 --port 8081 > "$ROOT/logs/api.log" 2>&1 &
cd "$ROOT/ui" && npm run dev > "$ROOT/logs/ui.log" 2>&1 &
echo "✅ Open http://localhost:3000"
BASH
chmod +x "$ROOT/start_all.sh"

echo "[7/7] 🚀 done"
echo "To launch later:"
echo "  cd $ROOT && bash start_all.sh"
