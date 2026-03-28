#!/usr/bin/env python3
"""Relay Claude hook events to the ClaudeTamagotchi server."""
import sys
import json
import urllib.request

EVENT = sys.argv[1] if len(sys.argv) > 1 else "unknown"

try:
    payload = json.load(sys.stdin)
except Exception:
    payload = {}

data = json.dumps({
    "event": EVENT,
    "session_id": payload.get("session_id", ""),
    "tool": payload.get("tool_name", "")
}).encode()

try:
    req = urllib.request.Request(
        "http://localhost:7777/hook",
        data=data,
        headers={"Content-Type": "application/json"}
    )
    urllib.request.urlopen(req, timeout=2)
except Exception:
    pass  # Server may not be running
