#!/usr/bin/env python3
"""Relay Claude hook events to the Clawdagotchi server."""
import sys
import json
import urllib.request

EVENT = sys.argv[1] if len(sys.argv) > 1 else "unknown"

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
}).encode()

if EVENT == "PermissionRequest":
    # Blocking request — hold open until user approves/denies in the app
    try:
        req = urllib.request.Request(
            "http://localhost:7777/permission",
            data=data,
            headers={"Content-Type": "application/json"}
        )
        resp = urllib.request.urlopen(req, timeout=300)
        result = json.loads(resp.read().decode())
        # Return hookSpecificOutput to Claude Code
        print(json.dumps(result))
    except Exception:
        pass  # Server not running or timeout — Claude Code proceeds normally
else:
    # Fire-and-forget for all other events
    try:
        req = urllib.request.Request(
            "http://localhost:7777/hook",
            data=data,
            headers={"Content-Type": "application/json"}
        )
        urllib.request.urlopen(req, timeout=2)
    except Exception:
        pass
