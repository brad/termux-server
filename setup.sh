#!/bin/bash

# Termux Service Setup Script
# Secure, Idempotent, and Easy to use.
# Copyright (c) 2026 Brad

# Exit on error
set -e

# Configuration
BRANCH="termux-service-setup-16714057685171292445"
BASE_URL="https://raw.githubusercontent.com/brad/termux-server/$BRANCH/services"

# Initial dependencies for fetching utils
pkg update -y
pkg install curl -y

# Fetch and source utilities
curl -sL --fail "$BASE_URL/utils.sh" -o "/tmp/utils.sh" || {
    echo "Error: Could not download utils.sh. Check your internet connection or the BRANCH variable."
    exit 1
}
source "/tmp/utils.sh"

# Initialize summary log
echo "" > "$SUMMARY_LOG"

echo -e "${GREEN}Starting Termux Service Setup...${NC}"

# 1. Setup Storage
echo -e "${YELLOW}Setting up storage access...${NC}"
if [ ! -d "$HOME/storage" ]; then
    termux-setup-storage || true
    echo "Please grant storage permission in the Android popup if it appears."
    sleep 2
fi

# 2. Update packages
echo -e "${YELLOW}Updating packages (this may take a minute)...${NC}"
export DEBIAN_FRONTEND=noninteractive
pkg upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

# 3. Install whiptail and other basics if not present
echo -e "${YELLOW}Installing dependencies...${NC}"
pkg install whiptail coreutils procps -y

# 4. Service selection
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
"Navidrome" "Subsonic Music Server" OFF \
"Nextcloud" "Cloud Storage (PHP/Lighttpd)" OFF 3>&1 1>&2 2>&3)

# Exit if cancelled
if [ $? -ne 0 ]; then
    echo "Setup cancelled."
    exit 0
fi

# 5. Process choices
for choice in $CHOICES; do
    c=$(echo "$choice" | tr -d '"' | tr '[:upper:]' '[:lower:]')
    echo -e "${YELLOW}Downloading and running setup for $c...${NC}"

    if curl -sL --fail "$BASE_URL/$c.sh" -o "/tmp/$c.sh"; then
        # We source the script so it can use the variables and functions from utils.sh
        source "/tmp/$c.sh"
        rm "/tmp/$c.sh"
    else
        echo -e "${RED}Error: Could not download setup script for $c${NC}"
    fi
done

# 6. Display Summary
echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}Setup Summary:${NC}"
cat "$SUMMARY_LOG"

echo -e "\n${YELLOW}Security Note:${NC}"
echo -e "Some services (Navidrome, Nextcloud, Mosquitto) are listening on 0.0.0.0"
echo -e "to be accessible on your home network. Ensure your router's firewall"
echo -e "is active and you haven't enabled DMZ for this device."

echo -e "${GREEN}====================================================${NC}"
echo -e "1. Install 'Termux:Boot' from F-Droid to start services on boot."
echo -e "2. Install 'Termux:Widget' from F-Droid for shortcuts."
echo -e "3. Long-press on your home screen -> Widgets -> Termux:Widget to add the shortcut panel."
echo -e "${GREEN}====================================================${NC}"

# Cleanup
rm "/tmp/utils.sh"
rm "$SUMMARY_LOG"
