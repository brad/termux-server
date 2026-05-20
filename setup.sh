#!/bin/bash

# Termux Service Setup Script
# Secure, Idempotent, and Easy to use.
# Copyright (c) 2026 Brad

# Exit on error
set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
BRANCH="termux-service-setup-16714057685171292445"
BASE_URL="https://raw.githubusercontent.com/brad/termux-server/$BRANCH/services"

# Initial dependencies for fetching utils
echo -e "${YELLOW}Updating package lists...${NC}"
if ! pkg update -y; then
    echo -e "${RED}Error: 'pkg update' failed.${NC}"
    echo -e "${YELLOW}This often happens if a mirror is down. Try running 'termux-change-repo' to select a different mirror.${NC}"
    exit 1
fi

if ! command -v curl &> /dev/null; then
    echo -e "${YELLOW}Installing curl...${NC}"
    if ! pkg install curl -y; then
        echo -e "${RED}Error: Failed to install curl.${NC}"
        echo -e "${YELLOW}Try running 'termux-change-repo' to select a different mirror.${NC}"
        exit 1
    fi
fi

# Detect Local Mode
USE_LOCAL=false
if [ -f "./services/utils.sh" ]; then
    echo -e "${GREEN}Local services directory detected. Using local files.${NC}"
    USE_LOCAL=true
    SERVICES_DIR="./services"
fi

# Fetch and source utilities
if [ "$USE_LOCAL" = true ]; then
    source "$SERVICES_DIR/utils.sh"
else
    echo -e "${YELLOW}Downloading utilities...${NC}"
    curl -sL --fail --retry 3 --connect-timeout 10 "$BASE_URL/utils.sh" -o "/tmp/utils.sh" || {
        echo -e "${RED}Error: Could not download utils.sh. Check your internet connection or the BRANCH variable.${NC}"
        exit 1
    }
    source "/tmp/utils.sh"
fi

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
    echo -e "${RED}Error: whiptail could not be installed. Please run 'pkg install whiptail' manually.${NC}"
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

    if [ "$USE_LOCAL" = true ]; then
        echo -e "${YELLOW}Running local setup for $c...${NC}"
        source "$SERVICES_DIR/$c.sh"
    else
        echo -e "${YELLOW}Downloading and running setup for $c...${NC}"
        if curl -sL --fail --retry 3 --connect-timeout 10 "$BASE_URL/$c.sh" -o "/tmp/$c.sh"; then
            # We source the script so it can use the variables and functions from utils.sh
            source "/tmp/$c.sh"
            rm "/tmp/$c.sh"
        else
            echo -e "${RED}Error: Could not download setup script for $c${NC}"
        fi
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
if [ "$USE_LOCAL" = false ]; then
    rm -f "/tmp/utils.sh"
fi
rm -f "$SUMMARY_LOG"
