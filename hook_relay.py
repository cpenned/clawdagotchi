#!/usr/bin/env python3
"""Relay Claude hook events to the Clawdagotchi server."""
import sys
import json
import urllib.request
import os

EVENT = sys.argv[1] if len(sys.argv) > 1 else "unknown"

TOKEN = ""
try:
    with open("/tmp/clawdagotchi.token", "r") as f:
        TOKEN = f.read().strip()
except Exception:
    pass

try:
    payload = json.load(sys.stdin)
except Exception:
    payload = {}

tool_input = ""
if "tool_input" in payload:
    try:
        tool_input = json.dumps(payload["tool_input"])[:200]
    except Exception:
        tool_input = str(payload["tool_input"])[:200]

data = json.dumps({
    "event": EVENT,
    "session_id": payload.get("session_id", ""),
    "tool": payload.get("tool_name", ""),
    "tool_input": tool_input,
    "cwd": payload.get("cwd", ""),
}).encode()

if EVENT == "PermissionRequest":
    # First check if server is reachable (quick 2s timeout)
    import socket
    server_up = False
    try:
        s = socket.create_connection(("127.0.0.1", 7777), timeout=2)
        s.close()
        server_up = True
    except Exception:
        pass

    if server_up:
        try:
            req = urllib.request.Request(
                "http://localhost:7777/permission",
                data=data,
                headers={"Content-Type": "application/json", "Authorization": f"Bearer {TOKEN}"}
            )
            resp = urllib.request.urlopen(req, timeout=300)
            result = json.loads(resp.read().decode())
            print(json.dumps(result))
        except Exception:
            pass
else:
    # Fire-and-forget for all other events
    try:
        req = urllib.request.Request(
            "http://localhost:7777/hook",
            data=data,
            headers={"Content-Type": "application/json", "Authorization": f"Bearer {TOKEN}"}
        )
        urllib.request.urlopen(req, timeout=2)
    except Exception:
        pass
