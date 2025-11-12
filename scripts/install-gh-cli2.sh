#!/usr/bin/env bash
set -euo pipefail

echo "[*] Installing GitHub CLI (gh) ..."

# Remove problematic repo if present
sudo rm -f /etc/apt/sources.list.d/google-cloud-sdk.list

# Add repository & key for gh
sudo apt update
sudo apt install -y curl gnupg apt-transport-https

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
  sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] \
  https://cli.github.com/packages stable main" | \
  sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null

sudo apt update
sudo apt install -y gh

echo "[*] Verifying gh ..."
gh --version

echo "[✓] GitHub CLI installed successfully."
