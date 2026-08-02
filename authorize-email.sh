#!/bin/bash
# Perform one-time Microsoft device-code authorization for weekly-reboot.

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

exec "$MAILER" authorize --env-file "$ENV_FILE"