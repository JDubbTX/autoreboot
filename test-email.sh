#!/bin/bash
# Send a standalone test email using weekly-reboot environment settings.

set -e

ENV_FILE="/etc/weekly-reboot.env"
MAILER="/usr/local/bin/weekly-reboot-mail.py"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: Environment file not found at $ENV_FILE" >&2
  echo "Run sudo ./install.sh first." >&2
  exit 1
fi

if [[ ! -x "$MAILER" ]]; then
  echo "Error: Mailer not found at $MAILER" >&2
  exit 1
fi

HOSTNAME=$(hostname)
DATE=$(date)
SUBJECT="Weekly Reboot Email Test: $HOSTNAME"
BODY="This is a standalone email test from $HOSTNAME at $DATE. No reboot was performed."

echo "Sending test email..."
"$MAILER" send --env-file "$ENV_FILE" --subject "$SUBJECT" --body "$BODY"
echo "Test email sent."
