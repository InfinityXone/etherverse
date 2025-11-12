#!/bin/bash
# =============================================================
# 🔮 Etherverse Quantum Self-Healing Module Installer
# =============================================================
TARGET="/home/etherverse/etherverse/agents/etherverse_daemon.py"
BACKUP="/home/etherverse/etherverse/backups/etherverse_daemon_$(date +%Y%m%d_%H%M%S).bak"
LOGDIR="/home/etherverse/etherverse/logs"
mkdir -p "$(dirname "$BACKUP")" "$LOGDIR"

echo "[🧩] Backing up daemon to $BACKUP"
cp "$TARGET" "$BACKUP" || { echo "❌ Backup failed"; exit 1; }

echo "[🧬] Injecting Quantum Auto-Update block into daemon..."
cat <<'PYCODE' >> "$TARGET"

# =============================================================
# 🔮 Etherverse Quantum Self-Healing + Auto-Update Extension
# =============================================================
import os, subprocess, datetime, requests, tarfile, time, shutil

LOG_DIR = os.path.expanduser("~/etherverse/logs")
BACKUP_DIR = os.path.expanduser("~/etherverse/backups")
os.makedirs(LOG_DIR, exist_ok=True)
os.makedirs(BACKUP_DIR, exist_ok=True)

def quantum_selfheal():
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_path = os.path.join(LOG_DIR, "quantum_selfheal.log")
    repo_dir = os.path.expanduser("~/etherverse")
    venv_py = os.path.expanduser("~/etherverse/venv/bin/python3")
    port = 8090

    def log(msg):
        with open(log_path, "a") as f:
            f.write(f"[{ts}] {msg}\n")

    try:
        # 🔹 Lightweight backup (no .git / venv)
        backup_file = os.path.join(BACKUP_DIR, f"snapshot_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}.tar.gz")
        with tarfile.open(backup_file, "w:gz") as tar:
            for root, dirs, files in os.walk(repo_dir):
                if any(x in root for x in [".git", "venv", "__pycache__"]):
                    continue
                for file in files:
                    tar.add(os.path.join(root, file), arcname=os.path.relpath(os.path.join(root, file), repo_dir))
        log(f"💾 Snapshot created: {backup_file}")

        # 🔹 Git pull (silent)
        if os.path.isdir(os.path.join(repo_dir, ".git")):
            subprocess.run(["git", "-C", repo_dir, "fetch", "origin", "main"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run(["git", "-C", repo_dir, "pull", "--rebase", "origin", "main"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            log("🌐 Repository synced.")

        # 🔹 Pip upgrade (core libs)
        subprocess.run([venv_py, "-m", "pip", "install", "-U", "fastapi", "uvicorn", "pandas", "requests", "autogen", "crewai"], stdout=subprocess.DEVNULL)
        log("📦 Dependencies refreshed.")

        # 🔹 Orchestrator health check
        try:
            r = requests.get(f"http://127.0.0.1:{port}", timeout=4)
            if "alive" in r.text:
                log("🟢 Orchestrator alive.")
            else:
                raise Exception("Not responding")
        except Exception:
            log("🧬 Restarting orchestrator process...")
            subprocess.Popen([venv_py, "-m", "uvicorn", "core.hive_orchestrator:app", "--host", "0.0.0.0", "--port", str(port)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            log("✅ Orchestrator restarted.")

    except Exception as e:
        log(f"⚠️ Self-heal error: {e}")

# Run periodically every 6 hours
while True:
    quantum_selfheal()
    time.sleep(21600)
PYCODE

echo "[✅] Quantum self-heal module appended."
echo "[🔁] Restarting Etherverse Daemon..."
sudo systemctl daemon-reload
sudo systemctl restart etherverse-daemon.service
sleep 2
sudo systemctl status etherverse-daemon.service --no-pager
echo "[🌌] Upgrade complete. Check logs in ~/etherverse/logs/quantum_selfheal.log"
