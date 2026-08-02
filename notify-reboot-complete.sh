#!/bin/bash
# Send a post-reboot completion email when triggered by the scheduled reboot flow.

set -e

MAILER="/usr/local/bin/weekly-reboot-mail.py"
ENV_FILE="/etc/weekly-reboot.env"
MARKER_FILE="/var/lib/weekly-reboot/pending-post-reboot-email"

if [[ ! -f "$MARKER_FILE" ]]; then
  echo "No pending reboot-complete notification marker found."
  exit 0
fi

if [[ ! -x "$MAILER" ]]; then
  echo "Error: Mailer not found at $MAILER" >&2
  exit 1
fi

HOSTNAME=$(hostname)
DATE=$(date)
SUBJECT="Scheduled Reboot Complete: $HOSTNAME"
BODY="The system $HOSTNAME has completed its scheduled weekly reboot and is back online as of $DATE."

echo "Sending post-reboot completion notification..."
"$MAILER" send --env-file "$ENV_FILE" --subject "$SUBJECT" --body "$BODY"

rm -f "$MARKER_FILE"
echo "Post-reboot completion notification sent."