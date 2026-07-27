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

echo "Removing files..."
rm -f /etc/systemd/system/weekly-reboot.service
rm -f /etc/systemd/system/weekly-reboot.timer
rm -f /usr/local/bin/notify-and-reboot.sh
rm -f /usr/local/bin/test-email.sh
rm -f /etc/weekly-reboot.env

if [[ -f /etc/s-nail.rc ]]; then
  sed -i '/^# BEGIN weekly-reboot managed SMTP config$/,/^# END weekly-reboot managed SMTP config$/d' /etc/s-nail.rc
fi

echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "Uninstallation complete."
