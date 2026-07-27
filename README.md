# Weekly Automatic Reboot with Email Notification

This project sets up a systemd timer to automatically reboot the machine every week on Sunday at 3:00 AM. It sends an email notification to `weirich_j@hotmail.com` just before the reboot occurs.

## Components

- `weekly-reboot.service`: The systemd service that triggers the notification script.
- `weekly-reboot.timer`: The systemd timer that schedules the weekly event.
- `notify-and-reboot.sh`: A bash script that sends the email and initiates the reboot.
- `install.sh`: Installation script (requires root).
- `uninstall.sh`: Removal script (requires root).

## Installation

1.  **Clone/Copy** these files to your machine.
2.  **Run the installation script**:
    ```bash
    sudo ./install.sh
    ```
3.  **Configure Email (Crucial)**:
    Since this system uses `s-nail` for mailing, you must configure your SMTP settings in `/etc/s-nail.rc` to ensure the emails are sent successfully.

    Add the following to the end of `/etc/s-nail.rc` (replace with your actual credentials):

    ```text
    set v15-compat
    set mta=smtp://user%40hotmail.com:YOUR_PASSWORD@smtp.office365.com:587
    set smtp-auth=login
    set smtp-use-starttls
    set from="Your Name <user@hotmail.com>"
    ```

    *Note: Use `%40` instead of `@` in the username part of the `mta` URL.*

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
- **Change the Schedule**:
  Edit `/etc/systemd/system/weekly-reboot.timer`, modify the `OnCalendar` line, then run `sudo systemctl daemon-reload`.

## Uninstallation

To remove the service and timer:
```bash
sudo ./uninstall.sh
```
