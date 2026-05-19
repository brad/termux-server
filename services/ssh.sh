#!/bin/bash
# SSH Setup for Termux
# Copyright (c) 2026 Brad

echo -e "${YELLOW}Setting up SSH...${NC}"
if ! command -v sshd &> /dev/null; then
    pkg install openssh -y
fi

# Enable boot via Termux:Boot
mkdir -p ~/.termux/boot
cat << BOOTEOF > ~/.termux/boot/start-ssh
#!/bin/bash
sshd
BOOTEOF
chmod +x ~/.termux/boot/start-ssh

# Shortcut to stop via Termux:Widget
mkdir -p ~/.shortcuts
echo "pkill sshd && echo 'SSH Stopped'" > ~/.shortcuts/stop-ssh
chmod +x ~/.shortcuts/stop-ssh

# Start now if not running
if ! pgrep -x sshd >/dev/null; then
    sshd
fi

log_summary "${GREEN}SSH setup complete.${NC}"
log_summary "${YELLOW}  - Run 'passwd' to set a password if you haven't already.${NC}"
log_summary "${YELLOW}  - For better security, use SSH keys: copy your public key to ~/.ssh/authorized_keys${NC}"
