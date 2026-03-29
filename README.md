# Clawdagotchi

A floating macOS desktop pet that reacts to your Claude Code sessions in real-time. Watch the pixel crab think, work, and celebrate as Claude processes your requests.

## Requirements

- macOS 15+
- Swift 6.0+ (Xcode 16+)

## Build & Run

### As .app bundle (recommended)

    bash build_app.sh
    open Clawdagotchi.app

### Quick dev mode

    swift build && swift run

## Install Hooks

    bash install_hooks.sh

Adds hooks to `~/.claude/settings.json` for PreToolUse, PostToolUse, Stop, SubagentStop, and PermissionRequest events. Safe to run multiple times.

## Features

- **Floating widget** — transparent, always-on-top Tamagotchi device on your desktop
- **Menubar icon** — quick access to show/hide widget, settings, and quit
- **Permission handling** — approve or deny Claude Code tool permissions from the device buttons
- **Sound effects** — optional audio feedback for events (uses macOS system sounds)
- **Resizable** — drag to resize, minimum 150x186
- **Settings** — toggle dock icon, menubar, widget visibility, sound effects

## Crab Expressions

| State | Eyes | Animation |
|-------|------|-----------|
| Idle | Normal + blink | Gentle bob |
| Thinking | Looking side-to-side | Eye wiggle |
| Working | Wide open | Walking legs |
| Done | Happy squish `> <` | Bounce |
| Permission | Alert (wide) | Pulsing border |

## Buttons

**Normal mode:** Left = poke, Right = pet. Buttons glow per active session count.

**Permission mode:** Left (red) = Deny, Right (green) = Allow. Screen shows the tool name.

## Test with curl

    curl -X POST http://localhost:7777/hook \
      -H 'Content-Type: application/json' \
      -H "Authorization: Bearer $(cat /tmp/clawdagotchi.token)" \
      -d '{"event":"PreToolUse","session_id":"test1","tool":"bash"}'
