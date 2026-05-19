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
export SUMMARY_LOG="/tmp/setup_summary.log"

# Function to log summary messages
log_summary() {
    echo -e "$1" >> "$SUMMARY_LOG"
}
