# ClaudeTamagotchi

A floating macOS widget that shows the state of your active Claude Code sessions as a cute Tamagotchi pet.

## Requirements

- macOS 15+
- Swift 6.0+ (Xcode 16+)

## Build & Run

    cd ~/Desktop/ClaudeTamagotchi
    swift build
    swift run

The widget appears as a small floating window. Right-click to quit.

## Install Hooks

    bash install_hooks.sh

This adds hook entries to `~/.claude/settings.json` that POST events to the widget. Safe to run multiple times.

## How It Works

The app runs a local HTTP server on port 7777. Claude Code hooks fire on tool use and session events, calling `hook_relay.py` which POSTs JSON to the server. The widget animates based on the current state:

- **Idle** — gentle bob, sleepy eyes
- **Thinking** — pulsing glow, animated dots
- **Working** — bouncing, sparkle particles
- **Done** — celebration bounce, checkmark

Sessions with no events for 60 seconds are automatically expired.

## Test with curl

    curl -X POST http://localhost:7777/hook \
      -H 'Content-Type: application/json' \
      -d '{"event":"PreToolUse","session_id":"test1","tool":"bash"}'
