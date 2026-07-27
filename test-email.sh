#!/bin/bash
# Send a standalone test email using weekly-reboot environment settings.

set -e

ENV_FILE="/etc/weekly-reboot.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: Environment file not found at $ENV_FILE" >&2
  echo "Run sudo ./install.sh first." >&2
  exit 1
fi

# shellcheck disable=SC1091
source "$ENV_FILE"

if [[ -z "$RECIPIENT_EMAIL" ]]; then
  echo "Error: RECIPIENT_EMAIL is not set in $ENV_FILE" >&2
  exit 1
fi

HOSTNAME=$(hostname)
DATE=$(date)
SUBJECT="Weekly Reboot Email Test: $HOSTNAME"
BODY="This is a standalone email test from $HOSTNAME at $DATE. No reboot was performed."

echo "Sending test email to $RECIPIENT_EMAIL..."
echo "$BODY" | mail -s "$SUBJECT" "$RECIPIENT_EMAIL"
echo "Test email command submitted."
