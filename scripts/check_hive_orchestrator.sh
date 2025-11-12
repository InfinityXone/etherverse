#!/usr/bin/env bash
# ============================================================
# 🧠 Etherverse Hive Orchestrator Health Check & Auto-Restart
# ============================================================

ORCH_PORT=8090
LOG_DIR="$HOME/etherverse/logs"
LOG_FILE="$LOG_DIR/hive_orchestrator.log"
APP_PATH="$HOME/etherverse/core/hive_orchestrator.py"
VENV_PATH="$HOME/etherverse/venv/bin/activate"

mkdir -p "$LOG_DIR"

echo "============================================================"
echo "🔍 Checking Etherverse Hive Orchestrator..."
echo "============================================================"

# Check if Uvicorn is running on the orchestrator port
if ss -tuln | grep -q ":$ORCH_PORT"; then
    PID=$(pgrep -f "hive_orchestrator")
    echo "✅ Hive Orchestrator is already running on port $ORCH_PORT"
    echo "🔹 PID: $PID"
    echo ""
    echo "📜 Showing last 15 log lines:"
    tail -n 15 "$LOG_FILE" 2>/dev/null || echo "⚠️ No log file found yet."
else
    echo "⚠️ Hive Orchestrator not detected — restarting..."
    source "$VENV_PATH"
    nohup python3 -m uvicorn core.hive_orchestrator:app \
        --host 0.0.0.0 --port "$ORCH_PORT" \
        > "$LOG_FILE" 2>&1 &

    sleep 3

    if ss -tuln | grep -q ":$ORCH_PORT"; then
        echo "✅ Hive Orchestrator successfully restarted on port $ORCH_PORT"
        echo "📜 Log file: $LOG_FILE"
    else
        echo "❌ Failed to start Hive Orchestrator. Check logs for details:"
        echo "   cat $LOG_FILE | tail -n 50"
    fi
fi

echo "============================================================"
