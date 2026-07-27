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
ENV_FILE="$SCRIPT_DIR/.env"
SYSTEM_ENV_FILE="/etc/weekly-reboot.env"
SNAIL_RC="/etc/s-nail.rc"

require_var() {
  local var_name="$1"
  if [[ -z "${!var_name}" ]]; then
    echo "Error: Required variable $var_name is not set in $ENV_FILE" >&2
    exit 1
  fi
}

echo "Installing dependencies (s-nail)..."
dnf install -y s-nail

echo "Installing weekly-reboot service, timer, and notification script..."

# Copy files to system directories
cp "$SCRIPT_DIR/weekly-reboot.service" /etc/systemd/system/
cp "$SCRIPT_DIR/weekly-reboot.timer" /etc/systemd/system/
cp "$SCRIPT_DIR/notify-and-reboot.sh" /usr/local/bin/
cp "$SCRIPT_DIR/test-email.sh" /usr/local/bin/

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: Missing $ENV_FILE" >&2
  echo "Create a .env file with: RECIPIENT_EMAIL=you@example.com" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

require_var "RECIPIENT_EMAIL"
require_var "SMTP_MTA"
require_var "SMTP_AUTH"
require_var "SMTP_FROM"

cp "$ENV_FILE" "$SYSTEM_ENV_FILE"

touch "$SNAIL_RC"

# Replace the managed SMTP block if it already exists.
sed -i '/^# BEGIN weekly-reboot managed SMTP config$/,/^# END weekly-reboot managed SMTP config$/d' "$SNAIL_RC"

{
  echo ""
  echo "# BEGIN weekly-reboot managed SMTP config"
  echo "set v15-compat"
  echo "set mta=$SMTP_MTA"
  echo "set smtp-auth=$SMTP_AUTH"
  if [[ "${SMTP_USE_STARTTLS:-true}" == "true" ]]; then
    echo "set smtp-use-starttls"
  fi
  echo "set from=\"$SMTP_FROM\""
  echo "# END weekly-reboot managed SMTP config"
} >> "$SNAIL_RC"

# Set appropriate permissions
chmod 644 /etc/systemd/system/weekly-reboot.service
chmod 644 /etc/systemd/system/weekly-reboot.timer
chmod 755 /usr/local/bin/notify-and-reboot.sh
chmod 755 /usr/local/bin/test-email.sh
chmod 600 "$SYSTEM_ENV_FILE"

# Reload systemd manager configuration
echo "Reloading systemd daemon..."
systemctl daemon-reload

# Enable and start the timer
echo "Enabling and starting weekly-reboot.timer..."
systemctl enable --now weekly-reboot.timer

echo "=========================================================="
echo "Weekly reboot timer has been successfully installed!"
echo "=========================================================="
echo "Recipient and SMTP settings loaded from: $SYSTEM_ENV_FILE"
echo "SMTP configuration written to: $SNAIL_RC"
echo "Run a send-only test with: sudo /usr/local/bin/test-email.sh"
echo ""
echo "Status of the timer:"
systemctl status weekly-reboot.timer --no-pager
