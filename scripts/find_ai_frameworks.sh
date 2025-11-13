#!/bin/bash
echo "[🤖] Scanning for AI frameworks and orchestration systems..."
echo "-----------------------------------------------------------"

SEARCH_ROOTS=("$HOME/etherverse" "$HOME" "/usr/local" "/opt" "/mnt/data")

# Output file
REPORT="$HOME/etherverse/logs/ai_frameworks_scan_$(date +%Y%m%d_%H%M%S).txt"
mkdir -p "$(dirname "$REPORT")"
echo "[📄] Writing report to: $REPORT" > "$REPORT"

# Define keyword categories
FRAMEWORKS=(
  "torch" "transformers" "langchain" "langgraph" "autogen"
  "crewai" "superagi" "llama" "ollama" "chroma" "faiss" "huggingface"
  "openai" "groq" "fastapi" "uvicorn" "flask" "asyncio" "aiohttp"
  "pydantic" "tiktoken" "litellm" "chromadb" "supabase" "firebase"
  "vectorstore" "agents" "autonomy" "finops" "swarm" "infinity" "etherverse"
)

echo "[🔍] Searching directories for frameworks and AI engines..." | tee -a "$REPORT"

for dir in "${SEARCH_ROOTS[@]}"; do
  echo "➡️  Checking $dir ..." | tee -a "$REPORT"
  find "$dir" -type f \( -name "*.py" -o -name "requirements*.txt" -o -name "pyproject.toml" -o -name "package.json" \) 2>/dev/null |
  grep -Ei "$(IFS=\|; echo "${FRAMEWORKS[*]}")" >> "$REPORT"
done

echo >> "$REPORT"
echo "[🧩] Installed Python packages (filtered for AI):" >> "$REPORT"
pip list 2>/dev/null | grep -Ei "torch|transformers|langchain|autogen|crewai|superagi|faiss|chromadb|huggingface|openai|groq" >> "$REPORT"

echo "-----------------------------------------------------------"
echo "[✅] Scan complete. Detailed log written to:"
echo "     $REPORT"
echo "[💡] To review results: cat \"$REPORT\" | less"
