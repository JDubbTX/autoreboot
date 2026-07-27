#!/bin/bash
# Script to notify via email and then reboot

RECIPIENT="weirich_j@hotmail.com"
HOSTNAME=$(hostname)
DATE=$(date)

echo "Sending pre-reboot notification to $RECIPIENT..."

# Attempt to send email. 
# Note: This requires SMTP to be configured in /etc/s-nail.rc or ~/.mailrc
echo "The system $HOSTNAME is about to perform its scheduled weekly reboot on $DATE." | mail -s "Scheduled Reboot Notification: $HOSTNAME" "$RECIPIENT"

# Give a short delay to ensure the mail process has a moment to initiate
sleep 5

echo "Initiating reboot..."
/usr/bin/systemctl reboot
