<div align="center">
  <h1>Clawdagotchi</h1>
  <p>A floating desktop pet that reacts to your Claude Code sessions in real-time.</p>
  <p>Take care of your crab — feed it, pet it, level it up, and clean up after it!</p>
</div>

## Features

- **Live Session Tracking** — Crab reacts to Claude Code activity with animated expressions
- **Permission Handling** — Approve or deny tool permissions directly from the widget
- **Pet Care** — Feed, pet, and poke your crab. Hunger and happiness bars drain over time
- **Mood System** — Crab sleeps, gets hungry, gets angry, and poops if you neglect it
- **XP & Leveling** — Earn XP from Claude Code usage and interactions. Unlock accessories
- **8 Accessories** — Bow tie, party hat, sunglasses, top hat, crown, headphones, star aura
- **Seasonal Events** — Santa hat in December, pumpkin in October, bunny ears in April, and more
- **LCD Backgrounds** — Stars, matrix, waves, circuit, and bubble patterns
- **Shell Styles** — 6 translucent case colors with Nothing-style transparent internals
- **Sound Effects** — Configurable sounds for every action
- **Daily Streaks** — Consecutive login tracking with bonus XP
- **Stats Dashboard** — Track sessions, tool uses, permissions, and pet care stats
- **Resizable** — Scale from 50% to 150% via Settings

## Requirements

- macOS 15+
- Claude Code CLI

## Install

Download the latest `.dmg` from [Releases](../../releases), open it, and drag Clawdagotchi to Applications.

Or build from source:

```bash
git clone https://github.com/YOUR_USERNAME/clawdagotchi.git
cd clawdagotchi
bash scripts/create-dmg.sh
open releases/Clawdagotchi-*.dmg
```

## Setup

After launching, install the Claude Code hooks:

```bash
bash install_hooks.sh
```

This adds hook entries to `~/.claude/settings.json` that relay events to the widget. Safe to run multiple times.

## How It Works

Clawdagotchi runs a local HTTP server on `127.0.0.1:7777` (localhost only). Claude Code hooks fire on tool use, session events, and permission requests, calling `hook_relay.py` which POSTs JSON to the server. The widget animates based on the current state.

Authentication is handled via a token written to `/tmp/clawdagotchi.token` on launch.

## Crab States

| State | Expression | Trigger |
|-------|-----------|---------|
| Idle | Gentle bob, periodic blink | No active sessions |
| Thinking | Eyes look side to side | PreToolUse |
| Working | Wide eyes, walking legs | PostToolUse |
| Done | Happy squish eyes | Stop/SubagentStop |
| Permission | Alert eyes, pulsing border | PermissionRequest |

## Pet Care

| Button | Normal Mode | Permission Mode |
|--------|------------|-----------------|
| Left | Poke (surprise) | Deny (red) |
| Middle | Feed (nom nom) | Info |
| Right | Pet (happy) | Allow (green) |

## Level System

| Level | XP | Accessory |
|-------|-----|-----------|
| 1 | 0 | None |
| 2 | 100 | Bow tie |
| 3 | 350 | Party hat |
| 4 | 800 | Sunglasses |
| 5 | 1,500 | Top hat |
| 6 | 2,500 | Crown |
| 7 | 4,000 | Headphones |
| 8 | 6,000 | Star aura |

## Settings

Right-click the widget to open Settings, or use Cmd+comma.

- **Appearance** — Pet name, crab color, shell style, background theme, seasonal toggle, size, float policy
- **Level Up** — Preview all levels and accessories with a slider
- **Stats** — Streak counter, session stats, pet care stats
- **Sound** — Configurable sounds per action with preview
- **About** — Feature guide, mood previews, version info

## Test with curl

```bash
TOKEN=$(cat /tmp/clawdagotchi.token)
curl -X POST http://localhost:7777/hook \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"event":"PreToolUse","session_id":"test","tool":"bash"}'
```

## Acknowledgments

- Crab geometry and hook architecture inspired by [Claude Island](https://github.com/farouqaldori/claude-island) (Apache 2.0)
- The Claude Code mascot ("Clawd") is a trademark of Anthropic

> This is an independent fan project. Not affiliated with, sponsored by, or endorsed by Anthropic.

## License

[Apache 2.0](LICENSE)
