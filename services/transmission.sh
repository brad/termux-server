#!/bin/bash
# Transmission Setup for Termux

echo -e "${YELLOW}Setting up Transmission...${NC}"
if ! command -v transmission-daemon &> /dev/null; then
    pkg install transmission -y
fi

# Enable boot
mkdir -p ~/.termux/boot
cat << 'EOF' > ~/.termux/boot/start-transmission
#!/bin/bash
transmission-daemon
EOF
chmod +x ~/.termux/boot/start-transmission

# Shortcut to stop
mkdir -p ~/.shortcuts
echo "pkill transmission-daemon && echo 'Transmission Stopped'" > ~/.shortcuts/stop-transmission
chmod +x ~/.shortcuts/stop-transmission

# Shortcut to open Web UI
echo "termux-open-url http://127.0.0.1:9091" > ~/.shortcuts/open-transmission
chmod +x ~/.shortcuts/open-transmission

# Start now
if ! pgrep -x transmission-da >/dev/null; then
    transmission-daemon
fi

log_summary "${GREEN}Transmission setup complete. Web UI at http://127.0.0.1:9091${NC}"
