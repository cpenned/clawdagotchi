# Polish & Hardening Design

**Goal:** Fix compiler warnings, harden the auto-updater against shell injection, improve download UX, and clean up temp files on cancel.

## Group A: Trivial Cleanup

### 1. Remove unused `sinceFed` variable
- `Sources/Clawdagotchi/TamagotchiViewModel.swift:244` — delete `let sinceFed = now.timeIntervalSince(lastFedTime)`

### 2. Fix SettingsView localization warnings
- `Sources/Clawdagotchi/SettingsView.swift:89` and `:203` — wrap enum values passed to `Text()` interpolation with `String(describing:)` to silence the `appendInterpolation` deprecation warnings

### 3. Add `releases/` to `.gitignore`
- Append `releases/` to `.gitignore` to prevent binary DMG files from being committed to git history

---

## Group B: Features & Hardening

### 4. Replace `shell()` with `run()` using `Process` args array

Remove the current `shell(_ command: String) -> Int32` helper which uses `/bin/sh -c` with string interpolation (shell injection risk if any path contains a single quote).

Replace with:

```swift
@discardableResult
private func run(_ binary: String, _ args: String...) -> Int32 {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: binary)
    process.arguments = args
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    try? process.run()
    process.waitUntilExit()
    return process.terminationStatus
}
```

Update all four callsites in `installUpdate`:

```swift
// Detach any existing mount
run("/usr/bin/hdiutil", "detach", mountPoint, "-quiet")

// Mount
let mountResult = run("/usr/bin/hdiutil", "attach", "-nobrowse", "-quiet", dmgPath.path, "-mountpoint", mountPoint)

// Copy
let copyResult = run("/usr/bin/ditto", "\(mountPoint)/Clawdagotchi.app", appDestination)

// Detach
run("/usr/bin/hdiutil", "detach", mountPoint, "-quiet")
```

No paths ever pass through a shell interpreter.

### 5. Download progress indicator

When the user clicks "Download" in `showUpdateAvailable`, the current alert dismisses and a new non-interactive modal appears:

```
"Downloading Clawdagotchi v{X}…"
[no buttons]
```

This alert is shown via `alert.window.orderFront(nil)` while the async download runs on a `Task`. When the download completes (success or failure), close the window programmatically, then either show the install prompt or fall back to the releases page.

Implementation: Show a `NSAlert` without buttons by not adding any, then call `alert.runModal()` on a background `Task` — but since `runModal()` is blocking, use `alert.window.makeKeyAndOrderFront(nil)` instead and track the window reference to close it after the download.

### 6. Clean up temp DMG on "Later"

In `showInstallPrompt`, when the user clicks "Later" (second button), delete the downloaded DMG:

```swift
if response == .alertFirstButtonReturn {
    installUpdate(dmgPath: dmgPath, releaseURL: releaseURL)
} else {
    try? FileManager.default.removeItem(at: dmgPath)
}
```

---

## File Map

- Modify: `Sources/Clawdagotchi/TamagotchiViewModel.swift` — remove `sinceFed`
- Modify: `Sources/Clawdagotchi/SettingsView.swift` — fix localization warnings
- Modify: `.gitignore` — add `releases/`
- Modify: `Sources/Clawdagotchi/UpdateChecker.swift` — replace `shell()` with `run()`, add progress alert, clean up on Later

## Out of Scope

- Re-offering install on next launch (user clicks Later → download discarded, will re-download on next check)
- Using `sinceFed` in mood logic (removed, not used)
- Certificate pinning
