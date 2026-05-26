#!/bin/bash
# Nextcloud Setup for Termux
# Copyright (c) 2026 Brad
# Adapted from BenjaminWegener/nextcloud_on_android

echo -e "${YELLOW}Setting up Nextcloud...${NC}"

# Install dependencies
DEBIAN_FRONTEND=noninteractive pkg install -y unzip sqlite php php-gd lighttpd wget coreutils lsof

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
    unzip -q "$FILE" -d "$HOME"
    [ -f "$FILE" ] && rm "$FILE"
fi

# Cleanup potentially broken config from previous runs (e.g. copied from config.sample.php)
if [ -f "$HOME/nextcloud/config/config.php" ]; then
    if grep -q "RedisCluster" "$HOME/nextcloud/config/config.php"; then
        echo "Detected broken config.php (copied from sample). Removing it to allow fresh setup..."
        rm "$HOME/nextcloud/config/config.php"
    fi
fi

# Ensure runtime directories exist
mkdir -p "$PREFIX/tmp"

# Verify php-cgi availability
if [ ! -f "$PREFIX/bin/php-cgi" ]; then
    echo -e "${RED}Error: php-cgi not found at $PREFIX/bin/php-cgi. Check php-cgi installation.${NC}"
    return 1 2>/dev/null || exit 1
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
    "mod_rewrite",
    "mod_setenv"
)
setenv.add-environment = (
    "PATH" => "/usr/local/bin:/usr/bin:/bin:$PREFIX/bin",
    "HOME" => "$HOME",
    "TMPDIR" => "$PREFIX/tmp"
)
fastcgi.server = ( ".php" => ((
                     "bin-path" => "$PREFIX/bin/php-cgi",
                     "socket" => "$PREFIX/tmp/php.socket",
                     "bin-environment" => (
                         "PHP_FCGI_CHILDREN" => "4",
                         "PHP_FCGI_MAX_REQUESTS" => "1000"
                     ),
                     "check-local" => "disable"
                 )))
LIGHTEOF

# Enable boot
mkdir -p ~/.termux/boot
cat << BOOTEOF > ~/.termux/boot/start-nextcloud
#!/bin/bash
termux-wake-lock
lighttpd -D -f ~/lighttpd.conf > /dev/null 2>&1 &
BOOTEOF
chmod +x ~/.termux/boot/start-nextcloud

# Shortcut to stop
mkdir -p ~/.shortcuts
echo "pkill lighttpd && pkill php-cgi && echo 'Nextcloud Stopped'" > ~/.shortcuts/stop-nextcloud
chmod +x ~/.shortcuts/stop-nextcloud

# Shortcut to open Web UI
echo "termux-open-url http://127.0.0.1:8080" > ~/.shortcuts/open-nextcloud
chmod +x ~/.shortcuts/open-nextcloud

# Test configuration
lighttpd -t -f ~/lighttpd.conf || {
    echo -e "${RED}Error: lighttpd configuration test failed. Check the output above.${NC}"
    return 1 2>/dev/null || exit 1
}

# Check for port conflicts
if lsof -i :8080 >/dev/null 2>&1; then
    CONFLICT_PID=$(lsof -t -i :8080)
    echo -e "${RED}Error: Port 8080 is already in use by PID $CONFLICT_PID.${NC}"
    echo -e "${YELLOW}Please stop the conflicting process or change the port in ~/lighttpd.conf.${NC}"
    return 1 2>/dev/null || exit 1
fi

# Start now
if ! pgrep -x lighttpd >/dev/null; then
    pkill php-cgi || true
    lighttpd -D -f ~/lighttpd.conf > /dev/null 2>&1 &
    sleep 1
    if ! pgrep -x lighttpd >/dev/null; then
        echo -e "${RED}Error: lighttpd failed to start. Check ~/lighttpd-error.log for details.${NC}"
        if [ -f "$HOME/lighttpd-error.log" ]; then
            echo -e "${YELLOW}Last 20 lines of ~/lighttpd-error.log:${NC}"
            tail -n 20 "$HOME/lighttpd-error.log"
        fi
        return 1 2>/dev/null || exit 1
    fi
fi

log_summary "${GREEN}Nextcloud setup complete. Web UI at http://[DEVICE_IP]:8080${NC}"
log_summary "${YELLOW}If you see 'Internal Server Error', check logs with:${NC}"
log_summary "  cat ~/lighttpd-error.log"
log_summary "  tail -n 50 ~/nextcloud/data/nextcloud.log"
