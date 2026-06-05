#!/bin/bash
# SSH Setup for Termux
# Copyright (c) 2026 Brad

echo -e "${YELLOW}Setting up SSH...${NC}"
if ! command -v sshd &> /dev/null; then
    pkg install openssh -y
fi

# Enable via termux-services
sv-enable sshd

# Shortcut to stop via Termux:Widget
mkdir -p ~/.shortcuts
echo 'sv down sshd && echo "SSH Stopped"' > ~/.shortcuts/stop-ssh
chmod +x ~/.shortcuts/stop-ssh

log_summary "${GREEN}SSH setup complete.${NC}"
log_summary "${YELLOW}  - Run 'passwd' to set a password if you haven't already.${NC}"
log_summary "${YELLOW}  - For better security, use SSH keys: copy your public key to ~/.ssh/authorized_keys${NC}"
