# 🔍 Find Etherverse daemon scripts and systemd configs
echo "[🧠] Scanning for Etherverse daemon files..."
ls -l ~/etherverse | grep -Ei "daemon|orchestrator|service|timer"

echo -e "\n[⚙️] Searching recursively for systemd-style or service files..."
find ~/etherverse -type f \( -iname "*daemon*" -o -iname "*service*" -o -iname "*orchestrator*" -o -iname "*timer*" \) 2>/dev/null | sort

echo -e "\n[🧩] Checking active systemd services related to Etherverse..."
systemctl list-units | grep -i etherverse || echo "⚠️ No active systemd units found for Etherverse"
