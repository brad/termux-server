#!/bin/bash
# Tailscale Setup for Termux
# Copyright (c) 2026 Brad

echo -e "${YELLOW}Setting up Tailscale...${NC}"
if ! command -v tailscaled &> /dev/null; then
    pkg install tailscale -y
fi

# Enable boot
mkdir -p ~/.termux/boot
cat << BOOTEOF > ~/.termux/boot/start-tailscale
#!/bin/bash
# Start tailscaled with user-space networking
tailscaled --tun=userspace-networking > /dev/null 2>&1 &

# Examples of how to serve various services via Tailscale:
# (Note: These require you to be logged in via 'tailscale up')
#
# SSH (Termux default port 8022):
# tailscale serve --bg tcp:22 tcp://localhost:8022
#
# Nextcloud:
# tailscale serve --bg https:443 / http://localhost:8080
#
# Syncthing:
# tailscale serve --bg https:8384 / http://localhost:8384
#
# Transmission:
# tailscale serve --bg https:9091 / http://localhost:9091
#
# Navidrome:
# tailscale serve --bg https:4533 / http://localhost:4533
#
# Mosquitto:
# tailscale serve --bg tcp:1883 tcp://localhost:1883
BOOTEOF
chmod +x ~/.termux/boot/start-tailscale

# Shortcut to stop
mkdir -p ~/.shortcuts
echo "pkill tailscaled && echo 'Tailscale Stopped'" > ~/.shortcuts/stop-tailscale
chmod +x ~/.shortcuts/stop-tailscale

# Start now if not running
if ! pgrep -x tailscaled >/dev/null; then
    tailscaled --tun=userspace-networking > /dev/null 2>&1 &
fi

log_summary "${GREEN}Tailscale setup complete.${NC}"
log_summary "${YELLOW}  - Run 'tailscale up' to log in.${NC}"
log_summary "${YELLOW}  - See ~/.termux/boot/start-tailscale for 'tailscale serve' examples.${NC}"
