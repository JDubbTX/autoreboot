#!/usr/bin/env python3
"""Send weekly reboot mail through Microsoft Graph using device-code OAuth."""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request


DEFAULT_TOKEN_FILE = "/var/lib/weekly-reboot/oauth-token.json"
DEFAULT_TENANT = "consumers"
GRAPH_SCOPE = "https://graph.microsoft.com/Mail.Send"
SCOPES = ["offline_access", GRAPH_SCOPE]


class MailConfigError(RuntimeError):
    pass


class OAuthError(RuntimeError):
    def __init__(self, error: str, description: str):
        self.error = error
        self.description = description
        super().__init__(f"{error}: {description}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=["authorize", "send"])
    parser.add_argument("--env-file", default="/etc/weekly-reboot.env")
    parser.add_argument("--subject")
    parser.add_argument("--body")
    return parser.parse_args()


def load_env_file(path: str) -> dict[str, str]:
    env: dict[str, str] = {}
    try:
        with open(path, "r", encoding="utf-8") as handle:
            for line in handle:
                stripped = line.strip()
                if not stripped or stripped.startswith("#"):
                    continue
                if "=" not in line:
                    raise MailConfigError(f"Invalid env line: {line.rstrip()}")
                key, value = line.split("=", 1)
                key = key.strip()
                value = value.strip()
                if value[:1] in {'"', "'"} and value[-1:] == value[:1]:
                    value = value[1:-1]
                env[key] = value
    except FileNotFoundError as exc:
        raise MailConfigError(f"Environment file not found: {path}") from exc
    return env


def require(env: dict[str, str], key: str) -> str:
    value = env.get(key, "").strip()
    if not value:
        raise MailConfigError(f"Required variable {key} is not set")
    return value


def token_file_path(env: dict[str, str]) -> str:
    return env.get("MICROSOFT_OAUTH_TOKEN_FILE", DEFAULT_TOKEN_FILE)


def endpoints(env: dict[str, str]) -> tuple[str, str]:
    tenant = env.get("MICROSOFT_OAUTH_TENANT", DEFAULT_TENANT)
    base = f"https://login.microsoftonline.com/{tenant}/oauth2/v2.0"
    return f"{base}/devicecode", f"{base}/token"


def post_form(url: str, data: dict[str, str]) -> dict[str, object]:
    encoded = urllib.parse.urlencode(data).encode("utf-8")
    request = urllib.request.Request(url, data=encoded, method="POST")
    request.add_header("Content-Type", "application/x-www-form-urlencoded")
    try:
        with urllib.request.urlopen(request) as response:
            return json.load(response)
    except urllib.error.HTTPError as exc:
        payload = exc.read().decode("utf-8", errors="replace")
        try:
            parsed = json.loads(payload)
        except json.JSONDecodeError as parse_exc:
            raise RuntimeError(f"HTTP {exc.code}: {payload}") from parse_exc
        error = str(parsed.get("error", "oauth_error"))
        description = str(parsed.get("error_description") or parsed)
        raise OAuthError(error, description) from exc


def post_json(url: str, access_token: str, payload: dict[str, object]) -> None:
    request = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        method="POST",
    )
    request.add_header("Authorization", f"Bearer {access_token}")
    request.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(request):
        return


def load_token_cache(path: str) -> dict[str, object]:
    try:
        with open(path, "r", encoding="utf-8") as handle:
            return json.load(handle)
    except FileNotFoundError:
        return {}


def save_token_cache(path: str, payload: dict[str, object]) -> None:
    directory = os.path.dirname(path)
    if directory:
        os.makedirs(directory, mode=0o700, exist_ok=True)
    temp_path = f"{path}.tmp"
    with open(temp_path, "w", encoding="utf-8") as handle:
        json.dump(payload, handle)
        handle.write("\n")
    os.chmod(temp_path, 0o600)
    os.replace(temp_path, path)


def normalize_token_payload(payload: dict[str, object], existing: dict[str, object]) -> dict[str, object]:
    refresh_token = payload.get("refresh_token") or existing.get("refresh_token")
    if not refresh_token:
        raise RuntimeError("Token response did not include a refresh token")
    expires_in = int(payload.get("expires_in", 0))
    return {
        "access_token": payload["access_token"],
        "refresh_token": refresh_token,
        "expires_at": int(time.time()) + expires_in,
        "scope": payload.get("scope", " ".join(SCOPES)),
        "token_type": payload.get("token_type", "Bearer"),
    }


def authorize(env: dict[str, str]) -> None:
    client_id = require(env, "MICROSOFT_OAUTH_CLIENT_ID")
    device_url, token_url = endpoints(env)
    device_response = post_form(
        device_url,
        {
            "client_id": client_id,
            "scope": " ".join(SCOPES),
        },
    )
    message = device_response.get("message")
    if message:
        print(message)
    else:
        print(
            "Open {uri} and enter code {code}".format(
                uri=device_response["verification_uri"],
                code=device_response["user_code"],
            )
        )

    interval = int(device_response.get("interval", 5))
    expires_at = int(time.time()) + int(device_response["expires_in"])

    while time.time() < expires_at:
        time.sleep(interval)
        try:
            token_response = post_form(
                token_url,
                {
                    "grant_type": "urn:ietf:params:oauth:grant-type:device_code",
                    "client_id": client_id,
                    "device_code": str(device_response["device_code"]),
                },
            )
        except OAuthError as exc:
            if exc.error == "authorization_pending" or "AADSTS70016" in exc.description:
                continue
            if exc.error == "slow_down":
                interval += 5
                continue
            raise

        cache = normalize_token_payload(token_response, {})
        save_token_cache(token_file_path(env), cache)
        print(f"Authorization complete. Token cache saved to {token_file_path(env)}")
        return

    raise RuntimeError("Device code expired before authorization completed")


def refresh_access_token(env: dict[str, str], cache: dict[str, object]) -> dict[str, object]:
    client_id = require(env, "MICROSOFT_OAUTH_CLIENT_ID")
    _, token_url = endpoints(env)
    refresh_token = str(cache.get("refresh_token", ""))
    if not refresh_token:
        raise RuntimeError("No refresh token cached. Run authorize-email.sh first.")
    token_response = post_form(
        token_url,
        {
            "client_id": client_id,
            "grant_type": "refresh_token",
            "refresh_token": refresh_token,
            "scope": " ".join(SCOPES),
        },
    )
    updated_cache = normalize_token_payload(token_response, cache)
    save_token_cache(token_file_path(env), updated_cache)
    return updated_cache


def access_token(env: dict[str, str]) -> str:
    cache = load_token_cache(token_file_path(env))
    now = int(time.time())
    if cache.get("access_token") and int(cache.get("expires_at", 0)) > now + 60:
        return str(cache["access_token"])
    refreshed = refresh_access_token(env, cache)
    return str(refreshed["access_token"])


def send_mail(env: dict[str, str], subject: str, body: str) -> None:
    recipient = require(env, "RECIPIENT_EMAIL")
    token = access_token(env)
    payload = {
        "message": {
            "subject": subject,
            "body": {
                "contentType": "Text",
                "content": body,
            },
            "toRecipients": [
                {
                    "emailAddress": {
                        "address": recipient,
                    }
                }
            ],
        },
        "saveToSentItems": True,
    }
    post_json("https://graph.microsoft.com/v1.0/me/sendMail", token, payload)
    print(f"Email sent to {recipient}")


def main() -> int:
    args = parse_args()
    try:
        env = load_env_file(args.env_file)
        if args.command == "authorize":
            authorize(env)
            return 0
        if not args.subject or not args.body:
            raise MailConfigError("send requires --subject and --body")
        send_mail(env, args.subject, args.body)
        return 0
    except (MailConfigError, RuntimeError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())