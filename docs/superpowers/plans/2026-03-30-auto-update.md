# Auto-Update Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the "open releases page" update flow with automatic DMG download + install, with Homebrew detection routing users to `brew upgrade` instead.

**Architecture:** All changes in `UpdateChecker.swift`. Homebrew installs are detected via bundle path. Direct installs download the DMG asset from the GitHub releases API, then mount/copy/relaunch using shell commands via `Process`.

**Tech Stack:** Swift, Foundation, AppKit, `hdiutil`, `ditto` (macOS built-ins)

---

## File Map

- **Modify:** `Sources/Clawdagotchi/UpdateChecker.swift` — all changes live here

---

### Task 1: Homebrew detection + download prompt

**Files:**
- Modify: `Sources/Clawdagotchi/UpdateChecker.swift`

- [ ] **Step 1: Add Homebrew detection and parse DMG asset URL from API response**

In `UpdateChecker.swift`, add the `isHomebrewInstall` property and update `check()` to extract the DMG download URL from the `assets` array. Update the `showUpdateAvailable` signature to accept an optional `dmgURL`.

Replace the entire file content with:

```swift
import Foundation
import AppKit

@MainActor
final class UpdateChecker {
    static let shared = UpdateChecker()
    private let repo = "cpenned/clawdagotchi"
    private let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

    private var isHomebrewInstall: Bool {
        let path = Bundle.main.bundlePath.lowercased()
        return path.contains("homebrew") || path.contains("cellar")
    }

    private init() {}

    func checkOnLaunch() {
        Task {
            try? await Task.sleep(for: .seconds(5))
            await check(silent: true)
        }
    }

    func checkNow() {
        Task {
            await check(silent: false)
        }
    }

    private func check(silent: Bool) async {
        guard let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest") else { return }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                if !silent { showUpToDate() }
                return
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tagName = json["tag_name"] as? String,
                  let htmlURL = json["html_url"] as? String else {
                if !silent { showUpToDate() }
                return
            }

            let latestVersion = tagName.replacingOccurrences(of: "v", with: "")

            // Extract DMG asset download URL
            var dmgURL: String? = nil
            if let assets = json["assets"] as? [[String: Any]] {
                dmgURL = assets
                    .first { ($0["name"] as? String)?.hasSuffix(".dmg") == true }
                    .flatMap { $0["browser_download_url"] as? String }
            }

            if isNewer(latestVersion, than: currentVersion) {
                showUpdateAvailable(version: latestVersion, releaseURL: htmlURL, dmgURL: dmgURL)
            } else if !silent {
                showUpToDate()
            }
        } catch {
            if !silent { showUpToDate() }
        }
    }

    private func isNewer(_ remote: String, than local: String) -> Bool {
        let r = remote.split(separator: ".").compactMap { Int($0) }
        let l = local.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(r.count, l.count) {
            let rv = i < r.count ? r[i] : 0
            let lv = i < l.count ? l[i] : 0
            if rv > lv { return true }
            if rv < lv { return false }
        }
        return false
    }

    private func showUpdateAvailable(version: String, releaseURL: String, dmgURL: String?) {
        if isHomebrewInstall {
            let alert = NSAlert()
            alert.messageText = "Update Available"
            alert.informativeText = "Clawdagotchi v\(version) is available.\n\nYou installed via Homebrew — run this to update:\n\nbrew upgrade clawdagotchi"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }

        guard let dmgURL else {
            // No DMG asset found — fall back to releases page
            openReleasesPage(releaseURL)
            return
        }

        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText = "Clawdagotchi v\(version) is available. You're running v\(currentVersion).\n\nDownload and install now?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Download")
        alert.addButton(withTitle: "Later")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            Task {
                await downloadAndInstall(version: version, dmgURL: dmgURL, releaseURL: releaseURL)
            }
        }
    }

    private func showUpToDate() {
        let alert = NSAlert()
        alert.messageText = "Up to Date"
        alert.informativeText = "You're running the latest version (v\(currentVersion))."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func openReleasesPage(_ url: String) {
        if let releaseURL = URL(string: url) {
            NSWorkspace.shared.open(releaseURL)
        }
    }

    // MARK: - Download & Install (implemented in Task 2 & 3)

    private func downloadAndInstall(version: String, dmgURL: String, releaseURL: String) async {
        // Task 2
    }

    @discardableResult
    private func shell(_ command: String) -> Int32 {
        // Task 3
        return -1
    }
}
```

- [ ] **Step 2: Build to verify it compiles**

```bash
swift build 2>&1
```

Expected: `Build complete!` (warnings OK, errors not OK)

- [ ] **Step 3: Commit**

```bash
git add Sources/Clawdagotchi/UpdateChecker.swift
git commit -m "feat: detect homebrew installs and prompt before downloading update"
```

---

### Task 2: Download the DMG

**Files:**
- Modify: `Sources/Clawdagotchi/UpdateChecker.swift`

- [ ] **Step 1: Implement `downloadAndInstall`**

Replace the stub `downloadAndInstall` method with:

```swift
private func downloadAndInstall(version: String, dmgURL: String, releaseURL: String) async {
    guard let url = URL(string: dmgURL) else {
        openReleasesPage(releaseURL)
        return
    }

    let tempDMG = FileManager.default.temporaryDirectory
        .appendingPathComponent("Clawdagotchi-\(version).dmg")

    // Remove any leftover temp file
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

- [ ] **Step 2: Build to verify it compiles**

```bash
swift build 2>&1
```

Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add Sources/Clawdagotchi/UpdateChecker.swift
git commit -m "feat: download DMG and prompt to install"
```

---

### Task 3: Mount, copy, relaunch, quit

**Files:**
- Modify: `Sources/Clawdagotchi/UpdateChecker.swift`

- [ ] **Step 1: Implement `shell`, `installUpdate`**

Replace the `shell` stub and add `installUpdate` after `showInstallPrompt`:

```swift
private func installUpdate(dmgPath: URL, releaseURL: String) {
    let mountPoint = "/tmp/clawdagotchi-update-mount"
    let appDestination = Bundle.main.bundlePath

    // Clean up any existing mount point
    shell("hdiutil detach '\(mountPoint)' -quiet 2>/dev/null || true")

    // Mount the DMG
    let mountResult = shell("hdiutil attach -nobrowse -quiet '\(dmgPath.path)' -mountpoint '\(mountPoint)'")
    guard mountResult == 0 else {
        openReleasesPage(releaseURL)
        return
    }

    // Copy the new app over the current one
    let copyResult = shell("ditto '\(mountPoint)/Clawdagotchi.app' '\(appDestination)'")

    // Detach regardless of copy result
    shell("hdiutil detach '\(mountPoint)' -quiet")

    guard copyResult == 0 else {
        openReleasesPage(releaseURL)
        return
    }

    // Clean up downloaded DMG
    try? FileManager.default.removeItem(at: dmgPath)

    // Relaunch the newly installed app
    let config = NSWorkspace.OpenConfiguration()
    NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: config) { _, _ in }

    // Quit current process
    NSApp.terminate(nil)
}

@discardableResult
private func shell(_ command: String) -> Int32 {
    let process = Process()
    process.launchPath = "/bin/sh"
    process.arguments = ["-c", command]
    // Suppress output
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    try? process.run()
    process.waitUntilExit()
    return process.terminationStatus
}
```

- [ ] **Step 2: Build to verify it compiles**

```bash
swift build 2>&1
```

Expected: `Build complete!`

- [ ] **Step 3: Smoke test manually**

Build and run the app:

```bash
bash build_app.sh && open Clawdagotchi.app
```

Go to Settings → About → Check for Updates. With the current build (v1.2.0) matching the latest release, it should say "Up to Date."

To test the update flow without releasing a new version, temporarily change `currentVersion` to `"1.0.0"` in `UpdateChecker.swift`, rebuild, and trigger a check. Verify:
- Alert says "Clawdagotchi v1.2.0 is available" with Download / Later
- Clicking Download triggers the download (should be fast) then shows "Ready to Install"
- Clicking Install & Restart mounts, copies, relaunches, and quits

Revert the version change afterward.

- [ ] **Step 4: Commit**

```bash
git add Sources/Clawdagotchi/UpdateChecker.swift
git commit -m "feat: mount dmg, copy app, and relaunch on install"
```

---

### Task 4: Push

- [ ] **Step 1: Push to remote**

```bash
git push
```
