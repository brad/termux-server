#!/bin/bash
# Mosquitto Setup for Termux
# Copyright (c) 2026 Brad

echo -e "${YELLOW}Setting up Mosquitto...${NC}"
if ! command -v mosquitto &> /dev/null; then
    pkg install mosquitto -y
fi

# Create secure configuration
mkdir -p ~/.config/mosquitto
cat << MOSQEOF > ~/.config/mosquitto/mosquitto.conf
# Listen on all interfaces
listener 1883 0.0.0.0

# Security: Disable anonymous access
allow_anonymous false

# Password file
password_file \$HOME/.config/mosquitto/passwd
MOSQEOF

# Initialize empty password file if it doesn't exist
if [ ! -f ~/.config/mosquitto/passwd ]; then
    touch ~/.config/mosquitto/passwd
    log_summary "${YELLOW}Mosquitto: No users configured. Run 'mosquitto_passwd -b ~/.config/mosquitto/passwd <username> <password>' to add a user.${NC}"
fi

# Enable boot
mkdir -p ~/.termux/boot
cat << BOOTEOF > ~/.termux/boot/start-mosquitto
#!/bin/bash
mosquitto -d -c \$HOME/.config/mosquitto/mosquitto.conf
BOOTEOF
chmod +x ~/.termux/boot/start-mosquitto

# Shortcut to stop
mkdir -p ~/.shortcuts
echo "pkill mosquitto && echo 'Mosquitto Stopped'" > ~/.shortcuts/stop-mosquitto
chmod +x ~/.shortcuts/stop-mosquitto

# Start now
if pgrep -x mosquitto >/dev/null; then
    pkill mosquitto
fi
mosquitto -d -c ~/.config/mosquitto/mosquitto.conf

log_summary "${GREEN}Mosquitto setup complete. Listener on 0.0.0.0:1883 (Auth Required).${NC}"
