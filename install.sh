#!/bin/bash
# Updated Install script for weekly-reboot with email notification

set -e

# Ensure the script is run with sudo/root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run as root. Please run with:" >&2
  echo "  sudo ./install.sh" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing dependencies (s-nail)..."
dnf install -y s-nail

echo "Installing weekly-reboot service, timer, and notification script..."

# Copy files to system directories
cp "$SCRIPT_DIR/weekly-reboot.service" /etc/systemd/system/
cp "$SCRIPT_DIR/weekly-reboot.timer" /etc/systemd/system/
cp "$SCRIPT_DIR/notify-and-reboot.sh" /usr/local/bin/

# Set appropriate permissions
chmod 644 /etc/systemd/system/weekly-reboot.service
chmod 644 /etc/systemd/system/weekly-reboot.timer
chmod 755 /usr/local/bin/notify-and-reboot.sh

# Reload systemd manager configuration
echo "Reloading systemd daemon..."
systemctl daemon-reload

# Enable and start the timer
echo "Enabling and starting weekly-reboot.timer..."
systemctl enable --now weekly-reboot.timer

echo "=========================================================="
echo "Weekly reboot timer has been successfully installed!"
echo "=========================================================="
echo "IMPORTANT: To receive emails, you MUST configure SMTP in /etc/s-nail.rc"
echo "Example configuration for Hotmail/Outlook:"
echo ""
echo "set v15-compat"
echo "set mta=smtp://user%40hotmail.com:password@smtp.office365.com:587"
echo "set smtp-auth=login"
echo "set smtp-use-starttls"
echo "set from=\"Your Name <user@hotmail.com>\""
echo ""
echo "Status of the timer:"
systemctl status weekly-reboot.timer --no-pager
