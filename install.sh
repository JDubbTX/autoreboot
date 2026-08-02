#!/bin/bash
# Install script for weekly-reboot with Microsoft Graph email notification

set -e

# Ensure the script is run with sudo/root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run as root. Please run with:" >&2
  echo "  sudo ./install.sh" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
SYSTEM_ENV_FILE="/etc/weekly-reboot.env"
STATE_DIR="/var/lib/weekly-reboot"

require_var() {
  local var_name="$1"
  if [[ -z "${!var_name}" ]]; then
    echo "Error: Required variable $var_name is not set in $ENV_FILE" >&2
    exit 1
  fi
}

echo "Installing dependencies (python3)..."
dnf install -y python3

echo "Installing weekly-reboot service, timer, and notification scripts..."

# Copy files to system directories
cp "$SCRIPT_DIR/weekly-reboot.service" /etc/systemd/system/
cp "$SCRIPT_DIR/weekly-reboot-complete.service" /etc/systemd/system/
cp "$SCRIPT_DIR/weekly-reboot.timer" /etc/systemd/system/
cp "$SCRIPT_DIR/notify-and-reboot.sh" /usr/local/bin/
cp "$SCRIPT_DIR/notify-reboot-complete.sh" /usr/local/bin/
cp "$SCRIPT_DIR/test-email.sh" /usr/local/bin/
cp "$SCRIPT_DIR/authorize-email.sh" /usr/local/bin/
cp "$SCRIPT_DIR/weekly-reboot-mail.py" /usr/local/bin/

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: Missing $ENV_FILE" >&2
  echo "Create a .env file with: RECIPIENT_EMAIL=you@example.com" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

require_var "RECIPIENT_EMAIL"
require_var "MICROSOFT_OAUTH_CLIENT_ID"

if [[ -z "$MICROSOFT_OAUTH_TENANT" ]]; then
  MICROSOFT_OAUTH_TENANT="consumers"
fi

if [[ -z "$MICROSOFT_OAUTH_TOKEN_FILE" ]]; then
  MICROSOFT_OAUTH_TOKEN_FILE="$STATE_DIR/oauth-token.json"
fi

cp "$ENV_FILE" "$SYSTEM_ENV_FILE"

sed -i '/^MICROSOFT_OAUTH_TENANT=/d;/^MICROSOFT_OAUTH_TOKEN_FILE=/d' "$SYSTEM_ENV_FILE"
printf 'MICROSOFT_OAUTH_TENANT=%q\n' "$MICROSOFT_OAUTH_TENANT" >> "$SYSTEM_ENV_FILE"
printf 'MICROSOFT_OAUTH_TOKEN_FILE=%q\n' "$MICROSOFT_OAUTH_TOKEN_FILE" >> "$SYSTEM_ENV_FILE"

mkdir -p "$STATE_DIR"

# Set appropriate permissions
chmod 644 /etc/systemd/system/weekly-reboot.service
chmod 644 /etc/systemd/system/weekly-reboot-complete.service
chmod 644 /etc/systemd/system/weekly-reboot.timer
chmod 755 /usr/local/bin/notify-and-reboot.sh
chmod 755 /usr/local/bin/notify-reboot-complete.sh
chmod 755 /usr/local/bin/test-email.sh
chmod 755 /usr/local/bin/authorize-email.sh
chmod 755 /usr/local/bin/weekly-reboot-mail.py
chmod 600 "$SYSTEM_ENV_FILE"
chmod 700 "$STATE_DIR"

# Reload systemd manager configuration
echo "Reloading systemd daemon..."
systemctl daemon-reload

# Enable and start the timer
echo "Enabling and starting weekly-reboot.timer..."
systemctl enable --now weekly-reboot.timer

echo "Enabling weekly-reboot-complete.service for post-boot completion notifications..."
systemctl enable weekly-reboot-complete.service

echo "=========================================================="
echo "Weekly reboot timer has been successfully installed!"
echo "=========================================================="
echo "Recipient and OAuth settings loaded from: $SYSTEM_ENV_FILE"
echo "OAuth token cache will be stored at: $MICROSOFT_OAUTH_TOKEN_FILE"
echo "Before sending mail, authorize the app once with:"
echo "  sudo /usr/local/bin/authorize-email.sh"
echo "Then test delivery with:"
echo "  sudo /usr/local/bin/test-email.sh"
echo ""
echo "Status of the timer:"
systemctl status weekly-reboot.timer --no-pager
