#!/bin/bash
# Script to notify via email and then reboot

set -e

MAILER="/usr/local/bin/weekly-reboot-mail.py"
ENV_FILE="/etc/weekly-reboot.env"
MARKER_FILE="/var/lib/weekly-reboot/pending-post-reboot-email"

if [[ ! -x "$MAILER" ]]; then
	echo "Error: Mailer not found at $MAILER" >&2
	exit 1
fi

HOSTNAME=$(hostname)
DATE=$(date)
SUBJECT="Scheduled Reboot Notification: $HOSTNAME"
BODY="The system $HOSTNAME is about to perform its scheduled weekly reboot on $DATE."

echo "Sending pre-reboot notification..."
"$MAILER" send --env-file "$ENV_FILE" --subject "$SUBJECT" --body "$BODY"

mkdir -p "$(dirname "$MARKER_FILE")"
touch "$MARKER_FILE"

echo "Initiating reboot..."
/usr/bin/systemctl reboot
