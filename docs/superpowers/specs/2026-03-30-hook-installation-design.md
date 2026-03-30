# Hook Installation Design

**Goal:** Allow new users to install Claude Code hooks directly from the app — no manual shell command required.

**Architecture:** Bundle `hook_relay.py` inside the `.app`, add `HookInstaller.swift` for detection/installation logic, show a blocking first-launch prompt if hooks aren't detected, and add a live status + button in the Settings About tab.

**Tech Stack:** Swift 6, SwiftUI, macOS 15+, SPM resource bundling

---

## Problem

`install_hooks.sh` hardcodes `$SCRIPT_DIR/hook_relay.py` (the repo path). Homebrew and DMG users who never clone the repo have no way to install hooks — the Setup section just says "Run: bash install_hooks.sh" with no path to find it.

---

## Solution

### 1. Bundle the Relay Script

Add `hook_relay.py` to the SPM target as a copied resource:

**`Package.swift`:** Add `resources: [.copy("Resources/hook_relay.py")]` to the executable target.

**`Sources/Clawdagotchi/Resources/hook_relay.py`:** Copy of the existing `hook_relay.py` from the repo root. This becomes `Clawdagotchi.app/Contents/Resources/hook_relay.py` after build.

---

### 2. HookInstaller.swift

New file. Provides two static functions:

**`areHooksInstalled() -> Bool`**
- Read `~/.claude/settings.json`
- Parse JSON, walk all hook command strings
- Return `true` if any contains `"hook_relay.py"`
- Return `false` on any parse/read failure

**`install() throws`**
1. Resolve bundled relay path: `Bundle.main.path(forResource: "hook_relay", ofType: "py")`
2. Create `~/.local/share/clawdagotchi/` if needed
3. Copy relay to `~/.local/share/clawdagotchi/hook_relay.py` (overwrite)
4. Read `~/.claude/settings.json` (create `{}` if missing); create `~/.claude/` dir if needed
5. For each of the 5 events (`PreToolUse`, `PostToolUse`, `Stop`, `SubagentStop`, `PermissionRequest`):
   - Skip if a command containing `hook_relay.py` already exists for that event
   - Append entry: `{ "matcher": "*", "hooks": [{ "type": "command", "command": "python3 \"/path/to/hook_relay.py\" EventName" }] }`
   - For `PermissionRequest` only: add `"timeout": 300000` to the hook def
6. Atomic write: write to temp file in same dir, then `rename` to replace

---

### 3. First-Launch Prompt

**`AppDelegate.applicationDidFinishLaunching`:**

After existing calls (`applyDockPolicy`, `checkOnLaunch`):

```
if !AppSettings.shared.hooksPromptShown && !HookInstaller.areHooksInstalled() {
    AppSettings.shared.hooksPromptShown = true
    // show NSAlert
}
```

Note: `hooksPromptShown` is a new `UserDefaults` key (defaults to `false`), so existing users who upgrade without having run `install_hooks.sh` will also see this prompt on their first launch after upgrading.

**Alert spec:**
- Title: "Install Claude Code Hooks?"
- Message: "Hooks let Clawdagotchi react to your Claude Code activity. This writes 5 hook entries to ~/.claude/settings.json and copies hook_relay.py to ~/.local/share/clawdagotchi/."
- Buttons: "Install" (default), "Skip"
- If Install: call `HookInstaller.install()`, show success alert "Hooks installed!" or error alert with the thrown error message
- Set `hooksPromptShown = true` before showing (prevent re-prompt regardless of outcome)

---

### 4. Settings About Tab — Setup Section

Replace the `darkAboutSection("Setup", ...)` text block with a custom view:

**Hook status row:**
- Label: "Claude Code Hooks"
- Status badge: "Installed" (salmon color) or "Not installed" (gray `#666`)
- Button "Install Hooks" — visible only when not installed
- On tap: call `HookInstaller.install()`, update status
- Status is read from `HookInstaller.areHooksInstalled()` on appear and after install attempt

Use `@State private var hooksInstalled: Bool` initialized in `.onAppear`.

---

### 5. AppSettings Addition

Add to `AppSettings`:

```swift
var hooksPromptShown: Bool {
    didSet { UserDefaults.standard.set(hooksPromptShown, forKey: "hooksPromptShown") }
}
```

Default: `false`

---

## File Map

| File | Change |
|------|--------|
| `Package.swift` | Add `resources: [.copy("Resources/hook_relay.py")]` |
| `Sources/Clawdagotchi/Resources/hook_relay.py` | New — copy of repo-root `hook_relay.py` |
| `Sources/Clawdagotchi/HookInstaller.swift` | New — detection + installation logic |
| `Sources/Clawdagotchi/AppDelegate.swift` | Add first-launch prompt |
| `Sources/Clawdagotchi/SettingsView.swift` | Replace Setup section in About tab |
| `Sources/Clawdagotchi/AppSettings.swift` | Add `hooksPromptShown` |

---

## Out of Scope

- Uninstalling hooks
- Updating hook paths if the user moves the app (relay lives in `~/.local/share/clawdagotchi/`, stable)
- Windows/Linux support
- Hook status in menu bar or elsewhere
