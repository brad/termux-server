#!/bin/bash
# Nextcloud Setup for Termux
# Copyright (c) 2026 Brad
# Adapted from BenjaminWegener/nextcloud_on_android

echo -e "${YELLOW}Setting up Nextcloud...${NC}"

# Install dependencies
pkg install -y unzip sqlite php lighttpd wget coreutils

# Download Nextcloud if not already present
if [ ! -d "$HOME/nextcloud" ]; then
    VERSION="33"
    EXPECTED_SHA="7331e9d45b742807719f01c436da12d7c34112962291346125551aa289df7eae661c9599f77af453cc423f73f4f339607aa8725dfb74c4c3c1145904b86f3564"
    FILE="latest-$VERSION.zip"
    URL="https://download.nextcloud.com/server/releases/$FILE"

    echo "Downloading Nextcloud $VERSION..."
    wget --https-only -O "$FILE" "$URL"

    echo "Verifying SHA512 checksum..."
    echo "$EXPECTED_SHA  $FILE" | sha512sum -c - || {
        echo -e "${RED}Error: SHA512 checksum verification failed!${NC}"
        rm "$FILE"
        return 1 2>/dev/null || exit 1
    }

    echo "Extracting Nextcloud..."
    unzip -q "$FILE"
    rm "$FILE"

    # Basic config initialization
    if [ -f "$HOME/nextcloud/config/config.sample.php" ]; then
        cp "$HOME/nextcloud/config/config.sample.php" "$HOME/nextcloud/config/config.php"
        # Allow any host for private network access
        sed -i "s/localhost:8080/*/g" "$HOME/nextcloud/config/config.php"
    fi
fi

# Configure lighttpd
cat << LIGHTEOF > ~/lighttpd.conf
server.port             = 8080
server.bind             = "0.0.0.0"
server.document-root    = "$HOME/nextcloud"
server.upload-dirs      = ( "$PREFIX/tmp" )
server.errorlog         = "$HOME/lighttpd-error.log"
accesslog.filename      = "$HOME/lighttpd-access.log"
index-file.names        = ( "index.php", "index.html" )
mimetype.assign = (
    ".html" => "text/html",
    ".txt" => "text/plain",
    ".css" => "text/css",
    ".js" => "application/x-javascript",
    ".jpg" => "image/jpeg",
    ".jpeg" => "image/jpeg",
    ".gif" => "image/gif",
    ".png" => "image/png",
    ".svg" => "image/svg+xml",
    "" => "application/octet-stream"
)
server.modules = (
    "mod_auth",
    "mod_access",
    "mod_accesslog",
    "mod_fastcgi",
    "mod_rewrite"
)
fastcgi.server = ( ".php" => ((
                     "bin-path" => "$PREFIX/bin/php-cgi",
                     "socket" => "$PREFIX/tmp/php.socket"
                 )))
LIGHTEOF

# Enable boot
mkdir -p ~/.termux/boot
cat << BOOTEOF > ~/.termux/boot/start-nextcloud
#!/bin/bash
termux-wake-lock
lighttpd -f ~/lighttpd.conf
BOOTEOF
chmod +x ~/.termux/boot/start-nextcloud

# Shortcut to stop
mkdir -p ~/.shortcuts
echo "pkill lighttpd && echo 'Nextcloud Stopped'" > ~/.shortcuts/stop-nextcloud
chmod +x ~/.shortcuts/stop-nextcloud

# Shortcut to open Web UI
echo "termux-open-url http://127.0.0.1:8080" > ~/.shortcuts/open-nextcloud
chmod +x ~/.shortcuts/open-nextcloud

# Test configuration
lighttpd -t -f ~/lighttpd.conf || {
    echo -e "${RED}Error: lighttpd configuration test failed. Check the output above.${NC}"
    return 1 2>/dev/null || exit 1
}

# Start now
if ! pgrep -x lighttpd >/dev/null; then
    lighttpd -f ~/lighttpd.conf
fi

log_summary "${GREEN}Nextcloud setup complete. Web UI at http://[DEVICE_IP]:8080${NC}"
