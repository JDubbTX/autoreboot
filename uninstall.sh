#!/bin/bash
# Uninstall script for weekly-reboot

set -e

# Ensure the script is run with sudo/root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run as root. Please run with:" >&2
  echo "  sudo ./uninstall.sh" >&2
  exit 1
fi

echo "Stopping and disabling weekly-reboot.timer..."
systemctl disable --now weekly-reboot.timer || true

echo "Disabling weekly-reboot-complete.service..."
systemctl disable weekly-reboot-complete.service || true

echo "Removing files..."
rm -f /etc/systemd/system/weekly-reboot.service
rm -f /etc/systemd/system/weekly-reboot-complete.service
rm -f /etc/systemd/system/weekly-reboot.timer
rm -f /usr/local/bin/notify-and-reboot.sh
rm -f /usr/local/bin/notify-reboot-complete.sh
rm -f /usr/local/bin/test-email.sh
rm -f /usr/local/bin/authorize-email.sh
rm -f /usr/local/bin/weekly-reboot-mail.py
rm -f /etc/weekly-reboot.env
rm -rf /var/lib/weekly-reboot

echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "Uninstallation complete."
