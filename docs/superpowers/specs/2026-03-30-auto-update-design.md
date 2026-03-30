# Auto-Update Design

**Goal:** When a new version is detected, automatically download and install it for direct-install users, with a prompt before each step. Homebrew users get a different message directing them to `brew upgrade`.

## Detection & Homebrew Branching

On version check, inspect `Bundle.main.bundlePath` before showing any download UI:

- If path contains `homebrew`, `Homebrew`, or `Cellar` → Homebrew install. Show alert: "You installed via Homebrew — run `brew upgrade clawdagotchi` to update." Dismiss only, no download.
- Otherwise → direct install. Proceed to download prompt.

## Download & Install Flow

1. **Update prompt**: "Clawdagotchi v{X} is available. Download now?" → Download / Later
2. **Download**: Fetch DMG URL from GitHub releases API `assets` array (find asset ending in `.dmg`). Download to a temp file via `URLSession`. Show "Downloading…" state (DMG is ~1MB, fast).
3. **Install prompt**: "Ready to install. Clawdagotchi will restart." → Install / Later
4. **Install sequence**:
   - `hdiutil attach -nobrowse -quiet {dmgPath}` → capture mount point
   - `ditto {mountPoint}/Clawdagotchi.app {Bundle.main.bundlePath}` → overwrite running app
   - `hdiutil detach {mountPoint}`
   - `NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, …)` → launch new copy
   - `NSApp.terminate(nil)` → quit current process
5. **Error fallback**: on any failure (download, mount, copy), open the GitHub releases page as before.

## Scope

- All changes in `Sources/Clawdagotchi/UpdateChecker.swift` — no new files.
- No new dependencies — uses only Foundation, AppKit, and shell tools available on macOS 15+.

## Out of Scope

- Delta/incremental updates
- Rollback
- Code signature verification of downloaded DMG (already handled by Gatekeeper on mount)
