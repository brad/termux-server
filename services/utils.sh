#!/bin/bash

# Shared utilities for Termux Service Setup

# Exit on error for all sourced scripts
set -e

# Colors
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export RED='\033[0;31m'
export NC='\033[0m'

# Summary log path
# Summary log path - uses WORKDIR if defined, else fallback to $TMPDIR or /tmp
if [ -n "$WORKDIR" ]; then
    export SUMMARY_LOG="$WORKDIR/setup_summary.log"
elif [ -n "$TMPDIR" ]; then
    export SUMMARY_LOG="$TMPDIR/setup_summary.log"
else
    export SUMMARY_LOG="/tmp/setup_summary.log"
fi

# Function to log summary messages
log_summary() {
    echo -e "$1" >> "$SUMMARY_LOG"
}

# Function to setup a runit service
setup_service() {
    local service_name=$1
    local run_command=$2
    local service_dir="$PREFIX/var/service/$service_name"

    echo -e "${YELLOW}Configuring runit service: $service_name...${NC}"

    # Create service and log directories
    mkdir -p "$service_dir/log"

    # Create run script
    cat << RUNEOF > "$service_dir/run"
#!/bin/bash
$run_command
RUNEOF
    chmod +x "$service_dir/run"

    # Link logger
    ln -sf "$PREFIX/share/termux-services/svlogger" "$service_dir/log/run"
}
