#!/bin/bash
# Navidrome Setup for Termux
# Copyright (c) 2026 Brad

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
    FILE="navidrome_${VERSION}_Linux_${NAV_ARCH}.tar.gz"
    URL="https://github.com/navidrome/navidrome/releases/download/v${VERSION}/$FILE"
    CHECKSUM_URL="https://github.com/navidrome/navidrome/releases/download/v${VERSION}/navidrome_checksums.txt"

    echo "Downloading Navidrome v${VERSION}..."
    curl -L --fail --retry 3 --connect-timeout 10 "$URL" -o "$FILE"

    echo "Verifying checksum..."
    curl -sL --fail --retry 3 --connect-timeout 10 "$CHECKSUM_URL" -o "navidrome_checksums.txt"
    grep "$FILE" "navidrome_checksums.txt" | sha256sum -c - || {
        echo -e "${RED}Error: SHA256 checksum verification failed!${NC}"
        rm "$FILE" "navidrome_checksums.txt"
        return 1 2>/dev/null || exit 1
    }

    tar -xz -f "$FILE" -C ~/bin navidrome
    rm "$FILE" "navidrome_checksums.txt"
    echo "Navidrome installed to ~/bin/navidrome"
fi

# Add ~/bin to path if not already there (for the current session)
export PATH="$HOME/bin:$PATH"

# Enable boot
mkdir -p ~/.termux/boot
cat << BOOTEOF > ~/.termux/boot/start-navidrome
#!/bin/bash
export PATH="\$HOME/bin:\$PATH"
cd ~ && navidrome --addr 0.0.0.0 > /dev/null 2>&1 &
BOOTEOF
chmod +x ~/.termux/boot/start-navidrome

# Shortcut to stop
mkdir -p ~/.shortcuts
echo "pkill navidrome && echo 'Navidrome Stopped'" > ~/.shortcuts/stop-navidrome
chmod +x ~/.shortcuts/stop-navidrome

# Shortcut to open Web UI
echo "termux-open-url http://127.0.0.1:4533" > ~/.shortcuts/open-navidrome
chmod +x ~/.shortcuts/open-navidrome

# Start now
if ! pgrep -x navidrome >/dev/null; then
    ~/bin/navidrome --addr 0.0.0.0 > /dev/null 2>&1 &
fi

log_summary "${GREEN}Navidrome setup complete. Web UI at http://[DEVICE_IP]:4533${NC}"
