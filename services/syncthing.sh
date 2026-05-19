#!/bin/bash
# Syncthing Setup for Termux

echo -e "${YELLOW}Setting up Syncthing...${NC}"
if ! command -v syncthing &> /dev/null; then
    pkg install syncthing -y
fi

# Enable boot
mkdir -p ~/.termux/boot
cat << 'EOF' > ~/.termux/boot/start-syncthing
#!/bin/bash
syncthing --no-browser > /dev/null 2>&1 &
EOF
chmod +x ~/.termux/boot/start-syncthing

# Shortcut to stop
mkdir -p ~/.shortcuts
echo "pkill syncthing && echo 'Syncthing Stopped'" > ~/.shortcuts/stop-syncthing
chmod +x ~/.shortcuts/stop-syncthing

# Shortcut to open Web UI
echo "termux-open-url http://127.0.0.1:8384" > ~/.shortcuts/open-syncthing
chmod +x ~/.shortcuts/open-syncthing

# Start now
if ! pgrep -x syncthing >/dev/null; then
    syncthing --no-browser > /dev/null 2>&1 &
fi

log_summary "${GREEN}Syncthing setup complete. Web UI at http://127.0.0.1:8384${NC}"
