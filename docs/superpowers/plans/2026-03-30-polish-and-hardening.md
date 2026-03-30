# Polish & Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix compiler warnings, harden shell invocation against injection, add download progress UX, and clean up temp files when the user cancels install.

**Architecture:** All changes are in `UpdateChecker.swift` and `TamagotchiViewModel.swift`. No new files. The shell helper is replaced with a variadic `run()` function that uses `Process` directly. The download progress window is shown non-modally using `makeKeyAndOrderFront` so it can be closed programmatically after the async download completes.

**Tech Stack:** Swift 6, AppKit, Foundation, macOS 15+

---

## File Map

- Modify: `Sources/Clawdagotchi/TamagotchiViewModel.swift` — remove unused `sinceFed`
- Modify: `Sources/Clawdagotchi/SettingsView.swift` — fix localization warnings
- Modify: `Sources/Clawdagotchi/UpdateChecker.swift` — replace `shell()` with `run()`, add progress window, clean up on Later

---

### Task 1: Fix compiler warnings

**Files:**
- Modify: `Sources/Clawdagotchi/TamagotchiViewModel.swift`
- Modify: `Sources/Clawdagotchi/SettingsView.swift`

- [ ] **Step 1: Remove unused `sinceFed` in TamagotchiViewModel.swift**

Find and delete line 244:
```swift
let sinceFed = now.timeIntervalSince(lastFedTime)
```

The surrounding lines should look like this after removal:
```swift
let now = Date()
let sinceInteraction = now.timeIntervalSince(lastInteractionTime)
let sincePoop = now.timeIntervalSince(lastPoopTime)
```

- [ ] **Step 2: Fix localization warnings in SettingsView.swift**

At line 89, `Text("Active now: \(seasonal)")` — `seasonal` is a `CrabAccessory` enum. Wrap it:
```swift
Text("Active now: \(String(describing: seasonal))")
```

At line 203, `Text("Unlocks: \(acc)")` — same fix:
```swift
Text("Unlocks: \(String(describing: acc))")
```

- [ ] **Step 3: Build to verify warnings are gone**

```bash
swift build 2>&1
```

Expected: `Build complete!` with no `appendInterpolation` warnings and no `sinceFed` warning.

- [ ] **Step 4: Commit**

```bash
git add Sources/Clawdagotchi/TamagotchiViewModel.swift Sources/Clawdagotchi/SettingsView.swift
git commit -m "fix: remove unused sinceFed variable and silence localization warnings"
```

---

### Task 2: Replace `shell()` with `run()` using Process args array

**Files:**
- Modify: `Sources/Clawdagotchi/UpdateChecker.swift`

The current `shell(_ command: String)` interpolates paths into a shell string, which is vulnerable to injection if a path contains a single quote. Replace it with `run(_ binary: String, _ args: String...)` that invokes the binary directly with no shell interpreter.

- [ ] **Step 1: Replace the `shell` method with `run`**

Remove the `shell` method (lines 202–212):
```swift
@discardableResult
private func shell(_ command: String) -> Int32 {
    let process = Process()
    process.launchPath = "/bin/sh"
    process.arguments = ["-c", command]
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    try? process.run()
    process.waitUntilExit()
    return process.terminationStatus
}
```

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

- [ ] **Step 2: Update all four callsites in `installUpdate`**

Replace the four `shell(...)` calls in `installUpdate` with `run(...)` calls. The full updated `installUpdate` method:

```swift
private func installUpdate(dmgPath: URL, releaseURL: String) {
    let mountPoint = "/tmp/clawdagotchi-update-mount"
    let appDestination = Bundle.main.bundlePath

    run("/usr/bin/hdiutil", "detach", mountPoint, "-quiet")

    let mountResult = run("/usr/bin/hdiutil", "attach", "-nobrowse", "-quiet", dmgPath.path, "-mountpoint", mountPoint)
    guard mountResult == 0 else {
        openReleasesPage(releaseURL)
        return
    }

    let copyResult = run("/usr/bin/ditto", "\(mountPoint)/Clawdagotchi.app", appDestination)

    run("/usr/bin/hdiutil", "detach", mountPoint, "-quiet")

    guard copyResult == 0 else {
        openReleasesPage(releaseURL)
        return
    }

    try? FileManager.default.removeItem(at: dmgPath)

    let config = NSWorkspace.OpenConfiguration()
    NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: config) { _, _ in }

    NSApp.terminate(nil)
}
```

- [ ] **Step 3: Build to verify it compiles**

```bash
swift build 2>&1
```

Expected: `Build complete!`

- [ ] **Step 4: Commit**

```bash
git add Sources/Clawdagotchi/UpdateChecker.swift
git commit -m "fix: replace shell string interpolation with Process args array"
```

---

### Task 3: Download progress window + clean up temp DMG on Later

**Files:**
- Modify: `Sources/Clawdagotchi/UpdateChecker.swift`

Two changes in one task since they both touch the download flow:

1. Show a non-modal "Downloading…" window while the DMG downloads, close it when done
2. Delete the temp DMG when the user clicks "Later" on the install prompt

The progress window uses `alert.window.makeKeyAndOrderFront(nil)` instead of `runModal()` so it can be closed programmatically after the async download finishes.

- [ ] **Step 1: Update `showUpdateAvailable` to show a progress window before downloading**

Replace the `if response == .alertFirstButtonReturn` block in `showUpdateAvailable` (currently lines 103–108):

```swift
let response = alert.runModal()
if response == .alertFirstButtonReturn {
    Task {
        await downloadAndInstall(version: version, dmgURL: dmgURL, releaseURL: releaseURL)
    }
}
```

With:

```swift
let response = alert.runModal()
if response == .alertFirstButtonReturn {
    let progressAlert = NSAlert()
    progressAlert.messageText = "Downloading Clawdagotchi v\(version)…"
    progressAlert.informativeText = "This will only take a moment."
    progressAlert.alertStyle = .informational
    progressAlert.layout()
    progressAlert.window.makeKeyAndOrderFront(nil)

    Task {
        await downloadAndInstall(version: version, dmgURL: dmgURL, releaseURL: releaseURL, progressWindow: progressAlert.window)
    }
}
```

- [ ] **Step 2: Update `downloadAndInstall` signature to accept and close the progress window**

Replace the current `downloadAndInstall` method:

```swift
private func downloadAndInstall(version: String, dmgURL: String, releaseURL: String) async {
    guard let url = URL(string: dmgURL) else {
        openReleasesPage(releaseURL)
        return
    }

    let tempDMG = FileManager.default.temporaryDirectory
        .appendingPathComponent("Clawdagotchi-\(version).dmg")

    try? FileManager.default.removeItem(at: tempDMG)

    do {
        let (downloadedURL, _) = try await URLSession.shared.download(from: url)
        try FileManager.default.moveItem(at: downloadedURL, to: tempDMG)
    } catch {
        openReleasesPage(releaseURL)
        return
    }

    showInstallPrompt(dmgPath: tempDMG, releaseURL: releaseURL)
}
```

With:

```swift
private func downloadAndInstall(version: String, dmgURL: String, releaseURL: String, progressWindow: NSWindow) async {
    guard let url = URL(string: dmgURL) else {
        progressWindow.close()
        openReleasesPage(releaseURL)
        return
    }

    let tempDMG = FileManager.default.temporaryDirectory
        .appendingPathComponent("Clawdagotchi-\(version).dmg")

    try? FileManager.default.removeItem(at: tempDMG)

    do {
        let (downloadedURL, _) = try await URLSession.shared.download(from: url)
        try FileManager.default.moveItem(at: downloadedURL, to: tempDMG)
    } catch {
        progressWindow.close()
        openReleasesPage(releaseURL)
        return
    }

    progressWindow.close()
    showInstallPrompt(dmgPath: tempDMG, releaseURL: releaseURL)
}
```

- [ ] **Step 3: Clean up temp DMG when user clicks "Later" in `showInstallPrompt`**

Replace the current `showInstallPrompt` method:

```swift
private func showInstallPrompt(dmgPath: URL, releaseURL: String) {
    let alert = NSAlert()
    alert.messageText = "Ready to Install"
    alert.informativeText = "The update has been downloaded. Clawdagotchi will restart to complete the installation."
    alert.alertStyle = .informational
    alert.addButton(withTitle: "Install & Restart")
    alert.addButton(withTitle: "Later")

    let response = alert.runModal()
    if response == .alertFirstButtonReturn {
        installUpdate(dmgPath: dmgPath, releaseURL: releaseURL)
    }
}
```

With:

```swift
private func showInstallPrompt(dmgPath: URL, releaseURL: String) {
    let alert = NSAlert()
    alert.messageText = "Ready to Install"
    alert.informativeText = "The update has been downloaded. Clawdagotchi will restart to complete the installation."
    alert.alertStyle = .informational
    alert.addButton(withTitle: "Install & Restart")
    alert.addButton(withTitle: "Later")

    let response = alert.runModal()
    if response == .alertFirstButtonReturn {
        installUpdate(dmgPath: dmgPath, releaseURL: releaseURL)
    } else {
        try? FileManager.default.removeItem(at: dmgPath)
    }
}
```

- [ ] **Step 4: Build to verify it compiles**

```bash
swift build 2>&1
```

Expected: `Build complete!`

- [ ] **Step 5: Commit**

```bash
git add Sources/Clawdagotchi/UpdateChecker.swift
git commit -m "feat: show download progress window, clean up temp DMG on cancel"
```

---

### Task 4: Push

- [ ] **Step 1: Push to remote**

```bash
git push
```
