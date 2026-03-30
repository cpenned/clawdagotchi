# Hook Installation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow users (new and existing) to install Claude Code hooks directly from the app, with a blocking first-launch prompt if hooks aren't detected.

**Architecture:** Bundle `hook_relay.py` as an SPM resource, add `HookInstaller.swift` for detection/installation logic, wire a first-launch `NSAlert` into `AppDelegate`, update the Settings About tab with live hook status + Install button, and add a `hooksPromptShown` flag to `AppSettings`.

**Tech Stack:** Swift 6, SwiftUI, macOS 15+, SPM resource bundling, Foundation JSON parsing

---

## File Map

| File | Action |
|------|--------|
| `Package.swift` | Add `resources: [.copy("Resources/hook_relay.py")]` |
| `Sources/Clawdagotchi/Resources/hook_relay.py` | New — copy of repo-root `hook_relay.py` |
| `Sources/Clawdagotchi/HookInstaller.swift` | New — `areHooksInstalled()` + `install()` |
| `Sources/Clawdagotchi/AppSettings.swift` | Add `hooksPromptShown: Bool` property |
| `Sources/Clawdagotchi/AppDelegate.swift` | Add first-launch prompt |
| `Sources/Clawdagotchi/SettingsView.swift` | Replace Setup section in About tab |

---

### Task 1: Bundle hook_relay.py as an SPM resource

**Files:**
- Modify: `Package.swift`
- Create: `Sources/Clawdagotchi/Resources/hook_relay.py`

- [ ] **Step 1: Create Resources directory and copy the relay script**

```bash
mkdir -p Sources/Clawdagotchi/Resources
cp hook_relay.py Sources/Clawdagotchi/Resources/hook_relay.py
```

- [ ] **Step 2: Update Package.swift to declare the resource**

Replace the entire `Package.swift` with:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Clawdagotchi",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "Clawdagotchi",
            path: "Sources/Clawdagotchi",
            resources: [.copy("Resources/hook_relay.py")]
        )
    ]
)
```

- [ ] **Step 3: Verify the build still succeeds**

```bash
swift build 2>&1 | tail -5
```

Expected: `Build complete!` (no errors)

- [ ] **Step 4: Verify the resource is in the built bundle**

```bash
find .build -name "hook_relay.py" 2>/dev/null
```

Expected: path like `.build/debug/Clawdagotchi_Clawdagotchi.bundle/hook_relay.py` or similar

- [ ] **Step 5: Commit**

```bash
git add Package.swift Sources/Clawdagotchi/Resources/hook_relay.py
git commit -m "feat: bundle hook_relay.py as SPM resource"
```

---

### Task 2: Add hooksPromptShown to AppSettings

**Files:**
- Modify: `Sources/Clawdagotchi/AppSettings.swift`

- [ ] **Step 1: Add the stored property after `seasonalAccessories`**

In `AppSettings.swift`, after line 60 (`var seasonalAccessories: Bool { ... }`), add:

```swift
    var hooksPromptShown: Bool {
        didSet { UserDefaults.standard.set(hooksPromptShown, forKey: "hooksPromptShown") }
    }
```

- [ ] **Step 2: Add the default in `defaults.register`**

In the `private init()`, inside the `defaults.register(defaults: [...])` block, add after `"seasonalAccessories": true,`:

```swift
            "hooksPromptShown": false,
```

- [ ] **Step 3: Initialize the property in init**

After `self.seasonalAccessories = defaults.bool(forKey: "seasonalAccessories")`, add:

```swift
        self.hooksPromptShown = defaults.bool(forKey: "hooksPromptShown")
```

- [ ] **Step 4: Build to verify no errors**

```bash
swift build 2>&1 | tail -5
```

Expected: `Build complete!`

- [ ] **Step 5: Commit**

```bash
git add Sources/Clawdagotchi/AppSettings.swift
git commit -m "feat: add hooksPromptShown setting"
```

---

### Task 3: Implement HookInstaller

**Files:**
- Create: `Sources/Clawdagotchi/HookInstaller.swift`

- [ ] **Step 1: Create HookInstaller.swift**

```swift
import Foundation

enum HookInstaller {
    static let relayDestination: URL = {
        let share = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".local/share/clawdagotchi")
        return share.appendingPathComponent("hook_relay.py")
    }()

    /// Returns true if any hook command in ~/.claude/settings.json references hook_relay.py
    static func areHooksInstalled() -> Bool {
        let settingsURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/settings.json")
        guard let data = try? Data(contentsOf: settingsURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let hooks = json["hooks"] as? [String: Any] else {
            return false
        }
        for (_, value) in hooks {
            guard let entries = value as? [[String: Any]] else { continue }
            for entry in entries {
                guard let hookList = entry["hooks"] as? [[String: Any]] else { continue }
                for hook in hookList {
                    if let cmd = hook["command"] as? String, cmd.contains("hook_relay.py") {
                        return true
                    }
                }
            }
        }
        return false
    }

    /// Copies hook_relay.py to ~/.local/share/clawdagotchi/ and writes hook entries to ~/.claude/settings.json
    static func install() throws {
        // 1. Locate bundled relay
        guard let bundledRelay = Bundle.main.path(forResource: "hook_relay", ofType: "py") else {
            throw HookInstallerError.relayNotInBundle
        }

        // 2. Copy to stable destination
        let destDir = relayDestination.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: relayDestination.path) {
            try FileManager.default.removeItem(at: relayDestination)
        }
        try FileManager.default.copyItem(atPath: bundledRelay, toPath: relayDestination.path)

        // 3. Read or create ~/.claude/settings.json
        let claudeDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".claude")
        try FileManager.default.createDirectory(at: claudeDir, withIntermediateDirectories: true)
        let settingsURL = claudeDir.appendingPathComponent("settings.json")

        var settings: [String: Any]
        if let data = try? Data(contentsOf: settingsURL),
           let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            settings = parsed
        } else {
            settings = [:]
        }

        // 4. Write hook entries
        var hooks = settings["hooks"] as? [String: Any] ?? [:]
        let events = ["PreToolUse", "PostToolUse", "Stop", "SubagentStop", "PermissionRequest"]
        let relayPath = relayDestination.path

        for event in events {
            var entries = hooks[event] as? [[String: Any]] ?? []
            let alreadyInstalled = entries.contains { entry in
                guard let hookList = entry["hooks"] as? [[String: Any]] else { return false }
                return hookList.contains { ($0["command"] as? String)?.contains("hook_relay.py") == true }
            }
            guard !alreadyInstalled else { continue }

            var hookDef: [String: Any] = [
                "type": "command",
                "command": "python3 \"\(relayPath)\" \(event)"
            ]
            if event == "PermissionRequest" {
                hookDef["timeout"] = 300000
            }
            let entry: [String: Any] = ["matcher": "*", "hooks": [hookDef]]
            entries.append(entry)
            hooks[event] = entries
        }
        settings["hooks"] = hooks

        // 5. Atomic write
        let jsonData = try JSONSerialization.data(withJSONObject: settings, options: [.prettyPrinted, .sortedKeys])
        let tmp = settingsURL.deletingLastPathComponent().appendingPathComponent(".settings.tmp.json")
        try jsonData.write(to: tmp, options: .atomic)
        _ = try FileManager.default.replaceItemAt(settingsURL, withItemAt: tmp)
    }
}

enum HookInstallerError: LocalizedError {
    case relayNotInBundle

    var errorDescription: String? {
        switch self {
        case .relayNotInBundle:
            return "hook_relay.py was not found in the app bundle."
        }
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
swift build 2>&1 | tail -5
```

Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add Sources/Clawdagotchi/HookInstaller.swift
git commit -m "feat: add HookInstaller with detection and install logic"
```

---

### Task 4: Add first-launch blocking prompt in AppDelegate

**Files:**
- Modify: `Sources/Clawdagotchi/AppDelegate.swift`

- [ ] **Step 1: Replace AppDelegate.swift**

```swift
import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppSettings.shared.applyDockPolicy()
        UpdateChecker.shared.checkOnLaunch()
        checkHooksOnLaunch()
    }

    func applicationWillTerminate(_ notification: Notification) {
        try? FileManager.default.removeItem(atPath: "/tmp/clawdagotchi.token")
    }

    func openSettingsFromKeyboard() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    private func checkHooksOnLaunch() {
        guard !AppSettings.shared.hooksPromptShown,
              !HookInstaller.areHooksInstalled() else { return }

        AppSettings.shared.hooksPromptShown = true

        let alert = NSAlert()
        alert.messageText = "Install Claude Code Hooks?"
        alert.informativeText = "Hooks let Clawdagotchi react to your Claude Code activity. This writes 5 hook entries to ~/.claude/settings.json and copies hook_relay.py to ~/.local/share/clawdagotchi/."
        alert.addButton(withTitle: "Install")
        alert.addButton(withTitle: "Skip")
        alert.alertStyle = .informational

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }

        do {
            try HookInstaller.install()
            let success = NSAlert()
            success.messageText = "Hooks Installed!"
            success.informativeText = "Clawdagotchi will now react to your Claude Code sessions. Restart Claude Code for hooks to take effect."
            success.addButton(withTitle: "OK")
            success.runModal()
        } catch {
            let failure = NSAlert()
            failure.messageText = "Hook Installation Failed"
            failure.informativeText = error.localizedDescription
            failure.alertStyle = .critical
            failure.addButton(withTitle: "OK")
            failure.runModal()
        }
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
swift build 2>&1 | tail -5
```

Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add Sources/Clawdagotchi/AppDelegate.swift
git commit -m "feat: show blocking hook install prompt on first launch"
```

---

### Task 5: Update Settings About tab with hook status UI

**Files:**
- Modify: `Sources/Clawdagotchi/SettingsView.swift`

Context: the About tab (`aboutTab`, starting around line 523) currently has a `darkAboutSection("Setup", ...)` text block at lines 569–573. Replace it with a live status row.

- [ ] **Step 1: Add @State for hooksInstalled near the top of SettingsView**

In `SettingsView`, find any existing `@State` declarations (look for `@State private var selectedTab`) and add alongside them:

```swift
    @State private var hooksInstalled: Bool = HookInstaller.areHooksInstalled()
```

- [ ] **Step 2: Replace the Setup darkAboutSection with a live status view**

Find and replace:

```swift
                darkAboutSection("Setup", """
1. Run: bash install_hooks.sh
2. Launch the app
3. Use Claude Code — the crab reacts!
""")
```

With:

```swift
                VStack(alignment: .leading, spacing: 8) {
                    Text("CLAUDE CODE HOOKS")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color(white: 0.33))
                        .tracking(1.5)
                    HStack {
                        Text(hooksInstalled ? "Installed" : "Not installed")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(hooksInstalled ? Color.salmon : Color(white: 0.4))
                        Spacer()
                        if !hooksInstalled {
                            Button("Install Hooks") {
                                do {
                                    try HookInstaller.install()
                                    hooksInstalled = true
                                } catch {
                                    let alert = NSAlert()
                                    alert.messageText = "Installation Failed"
                                    alert.informativeText = error.localizedDescription
                                    alert.alertStyle = .critical
                                    alert.addButton(withTitle: "OK")
                                    alert.runModal()
                                }
                            }
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Color.salmon)
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(10)
                    .background(Color(white: 0.145))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .onAppear { hooksInstalled = HookInstaller.areHooksInstalled() }
```

- [ ] **Step 3: Build to verify**

```bash
swift build 2>&1 | tail -5
```

Expected: `Build complete!`

- [ ] **Step 4: Smoke test — build app and open settings**

```bash
swift build && bash build_app.sh && open Clawdagotchi.app
```

Open Settings → About tab → verify "CLAUDE CODE HOOKS" section appears, showing either "Installed" or "Not installed" with button.

- [ ] **Step 5: Commit**

```bash
git add Sources/Clawdagotchi/SettingsView.swift
git commit -m "feat: add live hook status with install button to About tab"
```

---

### Task 6: End-to-end smoke test and version bump

**Files:**
- Modify: `Info.plist`

- [ ] **Step 1: Verify first-launch prompt flow**

Reset prompt flag to test the flow:

```bash
defaults delete com.clawdagotchi.app hooksPromptShown 2>/dev/null || true
```

If you want to also simulate no hooks installed, temporarily rename `~/.claude/settings.json`:

```bash
mv ~/.claude/settings.json ~/.claude/settings.json.bak
```

Open the app:

```bash
open Clawdagotchi.app
```

Expected: blocking `NSAlert` appears asking to install hooks. Click "Install". Expected: success alert appears. Verify:

```bash
cat ~/.claude/settings.json | python3 -m json.tool | grep hook_relay
```

Expected: 5 lines containing `hook_relay.py`. Restore backup if you moved it:

```bash
mv ~/.claude/settings.json.bak ~/.claude/settings.json 2>/dev/null || true
```

- [ ] **Step 2: Verify Settings About tab**

Open Settings → About tab. Confirm the CLAUDE CODE HOOKS row shows "Installed" in salmon. Confirm no Install button is visible.

- [ ] **Step 3: Bump version to 1.6.0 in Info.plist**

In `Info.plist`, update:
- `CFBundleShortVersionString` → `1.6.0`
- `CFBundleVersion` → `7`

- [ ] **Step 4: Commit**

```bash
git add Info.plist
git commit -m "chore: bump version to 1.6.0"
```
