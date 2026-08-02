# Weekly Automatic Reboot with Email Notification

This project sets up a systemd timer to automatically reboot the machine every week on Sunday at 3:00 AM. It sends an email notification through Microsoft Graph just before reboot and another email after the reboot has completed.

## Components

- `weekly-reboot.service`: The systemd service that triggers the notification script.
- `weekly-reboot-complete.service`: The systemd service that sends a post-boot completion email.
- `weekly-reboot.timer`: The systemd timer that schedules the weekly event.
- `weekly-reboot-mail.py`: Python mail sender that uses Microsoft Graph OAuth.
- `authorize-email.sh`: One-time device-code authorization helper.
- `notify-and-reboot.sh`: A bash script that sends the email and initiates the reboot.
- `notify-reboot-complete.sh`: A bash script that sends the post-reboot completion email.
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
    Then edit `.env` and set your recipient + Microsoft OAuth values:
    ```text
    RECIPIENT_EMAIL=you@example.com
    MICROSOFT_OAUTH_CLIENT_ID=your-app-client-id
    MICROSOFT_OAUTH_TENANT=consumers
    MICROSOFT_OAUTH_TOKEN_FILE=/var/lib/weekly-reboot/oauth-token.json
    ```
3.  **Run the installation script**:
    ```bash
    sudo ./install.sh
    ```
4.  **Authorize the app once**:
    ```bash
    sudo /usr/local/bin/authorize-email.sh
    ```
    The script prints a Microsoft device code and verification URL. Complete that sign-in with the Hotmail/Outlook account that should send the mail. Run this step with `sudo` because the systemd service uses the root-owned token cache.

5.  **Send a test email**:
    ```bash
    sudo /usr/local/bin/test-email.sh
    ```

## Microsoft App Setup

Create an app registration in Azure/Microsoft Entra before installing:

Microsoft Entra app registration is available on free Microsoft accounts such as outlook.com and hotmail.com email addresses. Creating the Azure account requires a credit card for identity verification and billing during sign-up, but this specific app registration flow (device-code OAuth + Microsoft Graph `Mail.Send`) is effectively free for long-term personal use.

1. Go to the Azure portal App registrations page.
2. Create a new app that supports personal Microsoft accounts.
3. Enable public client flows for the app.
4. Add delegated Microsoft Graph permission `Mail.Send`.
5. Copy the Application (client) ID into `MICROSOFT_OAUTH_CLIENT_ID`.

This project uses device-code OAuth with a cached refresh token, so it works for batch execution after the one-time interactive authorization.

## Management

- **Check Timer Status**:
  ```bash
  systemctl status weekly-reboot.timer
  ```
- **Check Reboot Completion Service Status**:
  ```bash
  systemctl status weekly-reboot-complete.service
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
- **Authorize or Re-authorize Microsoft OAuth**:
  ```bash
  sudo /usr/local/bin/authorize-email.sh
  ```
- **Change the Schedule**:
  Edit `/etc/systemd/system/weekly-reboot.timer`, modify the `OnCalendar` line, then run `sudo systemctl daemon-reload`.

## Uninstallation

To remove the service and timer:
```bash
sudo ./uninstall.sh
```
