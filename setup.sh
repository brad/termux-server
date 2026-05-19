#!/bin/bash

# Termux Service Setup Script
# Secure, Idempotent, and Easy to use.

# Exit on error
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Starting Termux Service Setup...${NC}"

# 1. Setup Storage
# This will trigger an Android permission dialog
echo -e "${YELLOW}Setting up storage access...${NC}"
if [ ! -d "$HOME/storage" ]; then
    # We use || true because termux-setup-storage might return non-zero if already running/denied
    termux-setup-storage || true
    echo "Please grant storage permission in the Android popup if it appears."
    sleep 2
fi

# 2. Update packages
# We use DEBIAN_FRONTEND=noninteractive to prevent the script from hanging on config file prompts
# which is likely why it "exited" or "stopped" for the user.
echo -e "${YELLOW}Updating packages (this may take a minute)...${NC}"
export DEBIAN_FRONTEND=noninteractive
pkg update -y
# Using force-confold to keep existing configs and avoid prompts during upgrade
pkg upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

# 3. Install whiptail and other basics if not present
echo -e "${YELLOW}Installing dependencies...${NC}"
pkg install whiptail coreutils procps curl -y

# 4. Service selection
# Ensure whiptail is available
if ! command -v whiptail &> /dev/null; then
    echo "Error: whiptail could not be installed. Please run 'pkg install whiptail' manually."
    exit 1
fi

CHOICES=$(whiptail --title "Termux Service Setup" --checklist \
"Select services to install and enable (Space to select, Enter to confirm):" 20 70 10 \
"SSH" "OpenSSH Server" ON \
"Syncthing" "File Synchronization" ON \
"Transmission" "BitTorrent Client" ON \
"Mosquitto" "MQTT Broker" OFF \
"Navidrome" "Subsonic Music Server" OFF 3>&1 1>&2 2>&3)

# Exit if cancelled (whiptail returns 1 for Cancel/ESC)
if [ $? -ne 0 ]; then
    echo "Setup cancelled."
    exit 0
fi

# 5. Create directories for boot and shortcuts
mkdir -p ~/.termux/boot
mkdir -p ~/.shortcuts

# Function to setup SSH
setup_ssh() {
    echo -e "${YELLOW}Setting up SSH...${NC}"
    if ! command -v sshd &> /dev/null; then
        pkg install openssh -y
    fi

    # Enable boot via Termux:Boot
    cat << 'EOF' > ~/.termux/boot/start-ssh
#!/bin/bash
sshd
EOF
    chmod +x ~/.termux/boot/start-ssh

    # Shortcut to stop via Termux:Widget
    echo "pkill sshd && echo 'SSH Stopped'" > ~/.shortcuts/stop-ssh
    chmod +x ~/.shortcuts/stop-ssh

    # Start now if not running
    if ! pgrep -x sshd >/dev/null; then
        sshd
    fi
    echo -e "${GREEN}SSH setup complete. Run 'passwd' to set a password.${NC}"
}

# Function to setup Syncthing
setup_syncthing() {
    echo -e "${YELLOW}Setting up Syncthing...${NC}"
    if ! command -v syncthing &> /dev/null; then
        pkg install syncthing -y
    fi

    # Enable boot
    cat << 'EOF' > ~/.termux/boot/start-syncthing
#!/bin/bash
syncthing --no-browser > /dev/null 2>&1 &
EOF
    chmod +x ~/.termux/boot/start-syncthing

    # Shortcut to stop
    echo "pkill syncthing && echo 'Syncthing Stopped'" > ~/.shortcuts/stop-syncthing
    chmod +x ~/.shortcuts/stop-syncthing

    # Shortcut to open Web UI
    echo "termux-open-url http://127.0.0.1:8384" > ~/.shortcuts/open-syncthing
    chmod +x ~/.shortcuts/open-syncthing

    # Start now
    if ! pgrep -x syncthing >/dev/null; then
        syncthing --no-browser > /dev/null 2>&1 &
    fi
    echo -e "${GREEN}Syncthing setup complete. Web UI at http://127.0.0.1:8384${NC}"
}

# Function to setup Transmission
setup_transmission() {
    echo -e "${YELLOW}Setting up Transmission...${NC}"
    if ! command -v transmission-daemon &> /dev/null; then
        pkg install transmission -y
    fi

    # Enable boot
    cat << 'EOF' > ~/.termux/boot/start-transmission
#!/bin/bash
transmission-daemon
EOF
    chmod +x ~/.termux/boot/start-transmission

    # Shortcut to stop
    echo "pkill transmission-daemon && echo 'Transmission Stopped'" > ~/.shortcuts/stop-transmission
    chmod +x ~/.shortcuts/stop-transmission

    # Shortcut to open Web UI
    echo "termux-open-url http://127.0.0.1:9091" > ~/.shortcuts/open-transmission
    chmod +x ~/.shortcuts/open-transmission

    # Start now
    if ! pgrep -x transmission-da >/dev/null; then
        transmission-daemon
    fi
    echo -e "${GREEN}Transmission setup complete. Web UI at http://127.0.0.1:9091${NC}"
}

# Function to setup Mosquitto
setup_mosquitto() {
    echo -e "${YELLOW}Setting up Mosquitto...${NC}"
    if ! command -v mosquitto &> /dev/null; then
        pkg install mosquitto -y
    fi

    # Enable boot
    cat << 'EOF' > ~/.termux/boot/start-mosquitto
#!/bin/bash
mosquitto -d
EOF
    chmod +x ~/.termux/boot/start-mosquitto

    # Shortcut to stop
    echo "pkill mosquitto && echo 'Mosquitto Stopped'" > ~/.shortcuts/stop-mosquitto
    chmod +x ~/.shortcuts/stop-mosquitto

    # Start now
    if ! pgrep -x mosquitto >/dev/null; then
        mosquitto -d
    fi
    echo -e "${GREEN}Mosquitto setup complete.${NC}"
}

# Function to setup Navidrome
setup_navidrome() {
    echo -e "${YELLOW}Setting up Navidrome...${NC}"
    if ! command -v navidrome &> /dev/null && [ ! -f ~/bin/navidrome ]; then
        mkdir -p ~/bin
        ARCH=$(uname -m)
        if [ "$ARCH" = "aarch64" ]; then
            NAV_ARCH="arm64"
        elif [[ "$ARCH" == arm* ]]; then
            NAV_ARCH="armv7"
        else
            NAV_ARCH="amd64"
        fi

        VERSION="0.51.1"
        URL="https://github.com/navidrome/navidrome/releases/download/v${VERSION}/navidrome_${VERSION}_Linux_${NAV_ARCH}.tar.gz"

        echo "Downloading Navidrome v${VERSION}..."
        if curl -L "$URL" | tar -xz -C ~/bin navidrome; then
            echo "Navidrome installed to ~/bin/navidrome"
        else
            echo "Failed to download Navidrome. Please check your internet connection or ARCH ($ARCH)."
            return
        fi
    fi

    # Add ~/bin to path if not already there (for the current session)
    export PATH="$HOME/bin:$PATH"

    # Enable boot
    cat << 'EOF' > ~/.termux/boot/start-navidrome
#!/bin/bash
export PATH="$HOME/bin:$PATH"
cd ~ && navidrome > /dev/null 2>&1 &
EOF
    chmod +x ~/.termux/boot/start-navidrome

    # Shortcut to stop
    echo "pkill navidrome && echo 'Navidrome Stopped'" > ~/.shortcuts/stop-navidrome
    chmod +x ~/.shortcuts/stop-navidrome

    # Shortcut to open Web UI
    echo "termux-open-url http://127.0.0.1:4533" > ~/.shortcuts/open-navidrome
    chmod +x ~/.shortcuts/open-navidrome

    # Start now
    if ! pgrep -x navidrome >/dev/null; then
        ~/bin/navidrome > /dev/null 2>&1 &
    fi
    echo -e "${GREEN}Navidrome setup complete. Web UI at http://127.0.0.1:4533${NC}"
}

# Process choices
# The CHOICES string looks like: "SSH" "Syncthing"
for choice in $CHOICES; do
    # Strip quotes
    c=$(echo "$choice" | tr -d '"')
    case "$c" in
        SSH) setup_ssh ;;
        Syncthing) setup_syncthing ;;
        Transmission) setup_transmission ;;
        Mosquitto) setup_mosquitto ;;
        Navidrome) setup_navidrome ;;
    esac
done

echo -e "${GREEN}====================================================${NC}"
echo -e "${GREEN}Setup complete!${NC}"
echo -e "1. Install 'Termux:Boot' from F-Droid to start services on boot."
echo -e "2. Install 'Termux:Widget' from F-Droid for shortcuts."
echo -e "3. Long-press on your home screen -> Widgets -> Termux:Widget to add the shortcut panel."
echo -e "${GREEN}====================================================${NC}"
