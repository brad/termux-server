#!/bin/bash
# Navidrome Setup for Termux

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
mkdir -p ~/.termux/boot
cat << 'EOF' > ~/.termux/boot/start-navidrome
#!/bin/bash
export PATH="$HOME/bin:$PATH"
cd ~ && navidrome > /dev/null 2>&1 &
EOF
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
    ~/bin/navidrome > /dev/null 2>&1 &
fi

log_summary "${GREEN}Navidrome setup complete. Web UI at http://127.0.0.1:4533${NC}"
