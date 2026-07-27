# Weekly Automatic Reboot with Email Notification

This project sets up a systemd timer to automatically reboot the machine every week on Sunday at 3:00 AM. It sends an email notification just before the reboot occurs.

## Components

- `weekly-reboot.service`: The systemd service that triggers the notification script.
- `weekly-reboot.timer`: The systemd timer that schedules the weekly event.
- `notify-and-reboot.sh`: A bash script that sends the email and initiates the reboot.
- `test-email.sh`: A bash script that sends a test email only (no reboot).
- `.env.example`: Template environment file for the recipient address.
- `install.sh`: Installation script (requires root).
- `uninstall.sh`: Removal script (requires root).

## Installation

1.  **Clone/Copy** these files to your machine.
2.  **Create your `.env` file** in this project directory:
    ```bash
    cp .env.example .env
    ```
    Then edit `.env` and set your recipient + SMTP values:
    ```text
    RECIPIENT_EMAIL=you@example.com
    SMTP_MTA=smtp://user%40hotmail.com:YOUR_PASSWORD@smtp.office365.com:587
    SMTP_AUTH=login
    SMTP_USE_STARTTLS=true
    SMTP_FROM="Your Name <user@hotmail.com>"
    ```
3.  **Run the installation script**:
    ```bash
    sudo ./install.sh
    ```
  4.  The installer copies `.env` to `/etc/weekly-reboot.env` and writes a managed SMTP block to `/etc/s-nail.rc`.

    *Note: Use `%40` instead of `@` in the username part of the `SMTP_MTA` URL.*

## Management

- **Check Timer Status**:
  ```bash
  systemctl status weekly-reboot.timer
  ```
- **List All Active Timers**:
  ```bash
  systemctl list-timers
  ```
- **Manually Trigger a Test (Warning: This will reboot the machine)**:
  ```bash
  sudo systemctl start weekly-reboot.service
  ```
- **Send a Test Email Only (No Reboot)**:
  ```bash
  sudo /usr/local/bin/test-email.sh
  ```
- **Change the Schedule**:
  Edit `/etc/systemd/system/weekly-reboot.timer`, modify the `OnCalendar` line, then run `sudo systemctl daemon-reload`.

## Uninstallation

To remove the service and timer:
```bash
sudo ./uninstall.sh
```
