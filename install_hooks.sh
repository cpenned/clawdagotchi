#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing ClaudeTamagotchi hooks..."

python3 << PYEOF
import json
import os

SETTINGS = os.path.expanduser("~/.claude/settings.json")
RELAY = "${SCRIPT_DIR}/hook_relay.py"
MARKER = "hook_relay.py"
EVENTS = ["PreToolUse", "PostToolUse", "Stop", "SubagentStop"]

try:
    with open(SETTINGS, "r") as f:
        settings = json.load(f)
except FileNotFoundError:
    settings = {}

hooks = settings.setdefault("hooks", {})
changed = False

for event in EVENTS:
    event_list = hooks.setdefault(event, [])

    already = any(
        MARKER in hook.get("command", "")
        for entry in event_list
        for hook in entry.get("hooks", [])
    )

    if already:
        print(f"  {event}: already installed")
        continue

    entry = {
        "matcher": "*",
        "hooks": [
            {
                "type": "command",
                "command": f"python3 {RELAY} {event}"
            }
        ]
    }
    event_list.append(entry)
    changed = True
    print(f"  {event}: installed")

if changed:
    with open(SETTINGS, "w") as f:
        json.dump(settings, f, indent=2)
        f.write("\n")
    print("\nHooks written to", SETTINGS)
else:
    print("\nAll hooks already installed, nothing changed.")
PYEOF
