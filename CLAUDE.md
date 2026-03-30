# Clawdagotchi — Project Notes

## Version Management

**Single source of truth: `Info.plist` → `CFBundleShortVersionString`**

When bumping the version:
1. Update `Info.plist` (CFBundleShortVersionString + CFBundleVersion)
2. Run `bash scripts/create-dmg.sh` — creates versioned + stable DMG
3. Notarize: `xcrun notarytool submit releases/Clawdagotchi-X.Y.Z.dmg --keychain-profile "notary" --wait`
4. Staple: `xcrun stapler staple releases/Clawdagotchi-X.Y.Z.dmg` then `cp releases/Clawdagotchi-X.Y.Z.dmg releases/Clawdagotchi.dmg`
5. Create GitHub release with BOTH DMGs:
   `gh release create vX.Y.Z releases/Clawdagotchi-X.Y.Z.dmg releases/Clawdagotchi.dmg`
6. Update Homebrew cask (`github.com/cpenned/homebrew-tap`):
   - Get new SHA: `shasum -a 256 releases/Clawdagotchi-X.Y.Z.dmg`
   - Update `version` and `sha256` in `Casks/clawdagotchi.rb`
7. The About tab and UpdateChecker read version from `Bundle.main.infoDictionary` at runtime

The `Clawdagotchi.dmg` (no version) is a stable-named copy used by the website's direct download links.

The Settings About tab, UpdateChecker, and DMG script all read from Info.plist automatically. Never hardcode version strings elsewhere.

## Download Links

All download CTAs (website, README) should point to:
```
https://github.com/cpenned/clawdagotchi/releases/latest
```
This always redirects to the latest release. Never hardcode a specific version in download links.

## GitHub

- Repo: https://github.com/cpenned/clawdagotchi
- Owner: cpenned (NOT chrispennington)
- Website domain: clawdagotchi.com

## Architecture

- **Swift app**: `Sources/Clawdagotchi/` — SPM executable target, macOS 15+
- **Marketing site**: `website/` — Astro + Tailwind + React island
- **Hook scripts**: `hook_relay.py` + `install_hooks.sh` at repo root
- **Build scripts**: `scripts/create-dmg.sh`, `scripts/generate-icon.sh`

## Key Design Decisions

- Crab color defaults to `#D97757` (Claude orange) — configurable in settings
- Accessories are always white for visibility on any crab color
- Shell has Nothing-style transparent internals with visible PCB
- The PermissionRequest hook checks server reachability (2s probe) before blocking — prevents hanging when app is closed
- XP and level persist across restarts; hunger/happiness/poop reset each launch
- Auth token written to `/tmp/clawdagotchi.token` with 0600 permissions, cleaned up on exit

## Common Issues

- **Hook timeout during git**: The PermissionRequest hook can block git operations if the app is running and a permission is pending. Kill the app first.
- **Code signing**: App is signed with Developer ID (team 5FS8D53Q69) and notarized with Apple. No Gatekeeper warnings.
- **Multiple instances**: Second instance fails to bind port 7777. Only run one at a time.

## Testing

```bash
# Build and run
swift build && bash build_app.sh && open Clawdagotchi.app

# Test hooks
TOKEN=$(cat /tmp/clawdagotchi.token)
curl -X POST http://localhost:7777/hook \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"event":"PostToolUse","session_id":"test","tool":"bash"}'

# Build website
cd website && npm run dev

# Build DMG
bash scripts/create-dmg.sh
```

## Dependencies

- Swift app: zero external dependencies (only Apple frameworks)
- Website: Astro, React, Tailwind, @fontsource/jetbrains-mono
