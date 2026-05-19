#!/bin/bash
# Mosquitto Setup for Termux

echo -e "${YELLOW}Setting up Mosquitto...${NC}"
if ! command -v mosquitto &> /dev/null; then
    pkg install mosquitto -y
fi

# Enable boot
mkdir -p ~/.termux/boot
cat << 'EOF' > ~/.termux/boot/start-mosquitto
#!/bin/bash
mosquitto -d
EOF
chmod +x ~/.termux/boot/start-mosquitto

# Shortcut to stop
mkdir -p ~/.shortcuts
echo "pkill mosquitto && echo 'Mosquitto Stopped'" > ~/.shortcuts/stop-mosquitto
chmod +x ~/.shortcuts/stop-mosquitto

# Start now
if ! pgrep -x mosquitto >/dev/null; then
    mosquitto -d
fi

log_summary "${GREEN}Mosquitto setup complete.${NC}"
