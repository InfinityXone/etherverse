#!/bin/bash
echo "🔍 Scanning Etherverse agents for REST API definitions..."
base="$HOME/etherverse/agents"
out="$HOME/etherverse/rest_agent_report.log"
> "$out"

printf "%-25s | %-8s | %-6s | %s\n" "Agent" "Framework" "Port" "Route Found?" | tee -a "$out"
printf "%-25s | %-8s | %-6s | %s\n" "-------------------------" "----------" "------" "--------------" | tee -a "$out"

find "$base" -maxdepth 2 -type f -name "agent.py" | while read -r f; do
  name=$(basename "$(dirname "$f")")
  fw=""
  port=""
  route=""

  grep -qi "FastAPI" "$f" && fw="FastAPI"
  grep -qi "Flask" "$f" && fw="Flask"
  grep -qi "Sanic" "$f" && fw="Sanic"
  grep -qi "aiohttp" "$f" && fw="aiohttp"
  grep -qi "uvicorn" "$f" && [ -z "$fw" ] && fw="Uvicorn"

  # detect port numbers
  port=$(grep -Eo "port\s*=\s*[0-9]{3,5}" "$f" | head -n1 | grep -Eo "[0-9]{3,5}")
  # detect route declarations
  grep -Eq "(@app\.get|@app\.post|@app\.route)" "$f" && route="yes" || route="no"

  [ -z "$fw" ] && fw="None"
  [ -z "$port" ] && port="-"

  printf "%-25s | %-8s | %-6s | %s\n" "$name" "$fw" "$port" "$route" | tee -a "$out"
done

echo "✅ Scan complete. Report saved to: $out"
