#!/usr/bin/env python3

import json
import os
import ssl
import sys
import time
import urllib.error
import urllib.request


def required_env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise SystemExit(f"{name} is required")
    return value


api = required_env("UNIFI_API").rstrip("/")
api_key = required_env("UNIFI_API_KEY")
mac = required_env("UNIFI_CLIENT_MAC").lower()
ip = required_env("UNIFI_CLIENT_IP")
dns = required_env("UNIFI_CLIENT_DNS")
name = required_env("UNIFI_CLIENT_NAME")
site = os.environ.get("UNIFI_SITE", "default").strip() or "default"
insecure = os.environ.get("UNIFI_INSECURE", "").lower() in {"1", "true", "yes", "on"}

ssl_context = ssl._create_unverified_context() if insecure else ssl.create_default_context()
headers = {
    "Accept": "application/json",
    "X-API-Key": api_key,
}


def request(path: str, method: str = "GET", payload=None):
    body = None
    request_headers = dict(headers)
    if payload is not None:
        body = json.dumps(payload).encode("utf-8")
        request_headers["Content-Type"] = "application/json"

    req = urllib.request.Request(
        f"{api}{path}",
        data=body,
        headers=request_headers,
        method=method,
    )

    try:
        with urllib.request.urlopen(req, context=ssl_context, timeout=10) as response:
            raw = response.read()
            return response.status, json.loads(raw) if raw else None
    except urllib.error.HTTPError as error:
        detail = error.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"UniFi API returned HTTP {error.code}: {detail}") from error
    except urllib.error.URLError as error:
        raise RuntimeError(f"Unable to reach UniFi API: {error.reason}") from error


active_path = f"/proxy/network/v2/api/site/{site}/clients/active"
deadline = time.monotonic() + 120
user_id = None

while time.monotonic() < deadline:
    try:
        _, active = request(active_path)
    except RuntimeError as error:
        print(error, file=sys.stderr)
        time.sleep(2)
        continue

    clients = active if isinstance(active, list) else (active or {}).get("data", [])
    for client in clients:
        if str(client.get("mac", "")).lower() == mac:
            user_id = client.get("user_id")
            break

    if user_id:
        break

    print(f"Waiting for UniFi to observe {mac}...", file=sys.stderr)
    time.sleep(2)

if not user_id:
    raise SystemExit(f"Timed out waiting for UniFi to observe {mac}")

# Network Application 10.x can report api.err.MacUsed when the provider tries to
# create an unconfigured observed client, then fail to look that client up through
# the legacy rest/user endpoint. Promote the observed client into rest/user first;
# the normal unifi_client resource can then take over management by MAC.
payload = {
    "_id": user_id,
    "mac": mac,
    "name": name,
    "fixed_ip": ip,
    "use_fixedip": True,
    "local_dns_record": dns,
    "local_dns_record_enabled": True,
}

request(
    f"/proxy/network/api/s/{site}/rest/user/{user_id}",
    method="PUT",
    payload=payload,
)

print(f"Bootstrapped UniFi client {mac} as {ip} ({dns})")
