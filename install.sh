#!/usr/bin/env bash
set -euo pipefail

# Check if being run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run with sudo" 
   exit 1
fi

# Get the actual user
if [[ -n "${SUDO_USER:-}" ]]; then
    readonly ACTUAL_USER="$SUDO_USER"
    readonly ACTUAL_HOME=$(eval echo "~$SUDO_USER")
else
    echo "Error: Could not determine the original user. Please run with sudo."
    exit 1
fi

echo "Installing for user: $ACTUAL_USER"

# Create .local/bin directory if it doesn't exist
sudo -u "$ACTUAL_USER" mkdir -p "$ACTUAL_HOME/.local/bin/"

# Copy script to user's bin directory
sudo -u "$ACTUAL_USER" cp ./rofi-wg "$ACTUAL_HOME/.local/bin/"

# Make it executable
sudo -u "$ACTUAL_USER" chmod +x "$ACTUAL_HOME/.local/bin/rofi-wg"

# Copy wrapper and give appropriate permissions
cp ./rofi-wg-wrapper /usr/local/sbin/
chown root:root /usr/local/sbin/rofi-wg-wrapper
chmod 700 /usr/local/sbin/rofi-wg-wrapper

# Create sudoers.d directory with proper permissions
if [[ ! -d /etc/sudoers.d/ ]]; then
    mkdir -p /etc/sudoers.d/
    chown root:root /etc/sudoers.d/
    chmod 750 /etc/sudoers.d/
fi
echo "$ACTUAL_USER ALL=(ALL) NOPASSWD: /usr/local/sbin/rofi-wg-wrapper" > /etc/sudoers.d/rofi-wg

# Set proper permissions on sudoers file
chmod 440 /etc/sudoers.d/rofi-wg

echo "Installation completed for user $ACTUAL_USER"
