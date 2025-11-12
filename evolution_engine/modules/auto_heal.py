#!/usr/bin/env python3
import subprocess, time

def restart_service(svc):
    try:
        subprocess.run(["sudo","systemctl","restart",svc], check=True)
        return f"Restarted {svc}"
    except Exception as e:
        return f"Failed to restart {svc}: {e}"

def main():
    actions = []
    status = subprocess.run(["systemctl","is-active","etherverse-auto-update.service"], capture_output=True, text=True).stdout.strip()
    if status != "active":
        actions.append(restart_service("etherverse-auto-update.service"))
    print("Auto-heal actions:")
    for a in actions:
        print(" -", a)

if __name__ == "__main__":
    main()
