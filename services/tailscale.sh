#!/bin/bash
# Tailscale Setup for Termux
# Copyright (c) 2026 Brad

echo -e "${YELLOW}Setting up Tailscale...${NC}"
if ! command -v tailscaled &> /dev/null; then
    pkg install tailscale -y
fi

# Enable via termux-services
setup_service "tailscaled" "exec tailscaled --tun=userspace-networking 2>&1"
sv-enable tailscaled

# Shortcut to stop
mkdir -p ~/.shortcuts
echo 'sv down tailscaled && echo "Tailscale Stopped"' > ~/.shortcuts/stop-tailscale
chmod +x ~/.shortcuts/stop-tailscale

log_summary "${GREEN}Tailscale setup complete.${NC}"
log_summary "${YELLOW}  - Run 'tailscale up' to log in.${NC}"
log_summary "${YELLOW}  - See sv logger output for tailscaled logs.${NC}"
