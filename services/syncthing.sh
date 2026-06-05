#!/bin/bash
# Syncthing Setup for Termux
# Copyright (c) 2026 Brad

echo -e "${YELLOW}Setting up Syncthing...${NC}"
if ! command -v syncthing &> /dev/null; then
    pkg install syncthing -y
fi

# Enable via termux-services
setup_service "syncthing" "exec syncthing --no-browser --gui-address=127.0.0.1:8384 2>&1"
sv-enable syncthing

# Shortcut to stop
mkdir -p ~/.shortcuts
echo 'sv down syncthing && echo "Syncthing Stopped"' > ~/.shortcuts/stop-syncthing
chmod +x ~/.shortcuts/stop-syncthing

# Shortcut to open Web UI
echo "termux-open-url http://127.0.0.1:8384" > ~/.shortcuts/open-syncthing
chmod +x ~/.shortcuts/open-syncthing

log_summary "${GREEN}Syncthing setup complete. Web UI at http://127.0.0.1:8384 (Local only)${NC}"
