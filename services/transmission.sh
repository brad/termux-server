#!/bin/bash
# Transmission Setup for Termux
# Copyright (c) 2026 Brad

echo -e "${YELLOW}Setting up Transmission...${NC}"
if ! command -v transmission-daemon &> /dev/null; then
    pkg install transmission -y
fi

# Enable via termux-services
setup_service "transmission" "exec transmission-daemon -f --allowed 127.0.0.1 --bind-address-ipv4 127.0.0.1 2>&1"
sv-enable transmission

# Shortcut to stop
mkdir -p ~/.shortcuts
echo 'sv down transmission && echo "Transmission Stopped"' > ~/.shortcuts/stop-transmission
chmod +x ~/.shortcuts/stop-transmission

# Shortcut to open Web UI
echo "termux-open-url http://127.0.0.1:9091" > ~/.shortcuts/open-transmission
chmod +x ~/.shortcuts/open-transmission

log_summary "${GREEN}Transmission setup complete. Web UI at http://127.0.0.1:9091 (Local only)${NC}"
