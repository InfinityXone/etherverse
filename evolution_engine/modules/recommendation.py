#!/usr/bin/env python3
import os, subprocess

def main():
    print("Recommendations:")
    status = subprocess.run(["systemctl","is-active","etherverse-auto-update.service"], capture_output=True, text=True).stdout.strip()
    if status != "active":
        print(" - Repair or enable etherverse-auto-update.service")
    else:
        print(" - System update service active; no action needed.")
if __name__ == "__main__":
    main()
