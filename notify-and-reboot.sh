#!/bin/bash
# Script to notify via email and then reboot

ENV_FILE="/etc/weekly-reboot.env"

if [[ ! -f "$ENV_FILE" ]]; then
	echo "Error: Environment file not found at $ENV_FILE" >&2
	exit 1
fi

# shellcheck disable=SC1091
source "$ENV_FILE"

if [[ -z "$RECIPIENT_EMAIL" ]]; then
	echo "Error: RECIPIENT_EMAIL is not set in $ENV_FILE" >&2
	exit 1
fi

RECIPIENT="$RECIPIENT_EMAIL"
HOSTNAME=$(hostname)
DATE=$(date)

echo "Sending pre-reboot notification to $RECIPIENT..."

# Attempt to send email.
# SMTP settings are managed by install.sh in /etc/s-nail.rc.
echo "The system $HOSTNAME is about to perform its scheduled weekly reboot on $DATE." | mail -s "Scheduled Reboot Notification: $HOSTNAME" "$RECIPIENT"

# Give a short delay to ensure the mail process has a moment to initiate
sleep 5

echo "Initiating reboot..."
/usr/bin/systemctl reboot
