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
                if !silent { showCheckFailed() }
                return
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tagName = json["tag_name"] as? String,
                  let htmlURL = json["html_url"] as? String else {
                if !silent { showCheckFailed() }
                return
            }

            let latestVersion = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName

            let dmgURL: String? = (json["assets"] as? [[String: Any]])?
                .first { ($0["name"] as? String)?.hasSuffix(".dmg") == true }
                .flatMap { $0["browser_download_url"] as? String }

            if isNewer(latestVersion, than: currentVersion) {
                showUpdateAvailable(version: latestVersion, releaseURL: htmlURL, dmgURL: dmgURL)
            } else if !silent {
                showUpToDate()
            }
        } catch {
            if !silent { showCheckFailed() }
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

    private func showCheckFailed() {
        let alert = NSAlert()
        alert.messageText = "Update Check Failed"
        alert.informativeText = "Could not reach GitHub. Check your connection and try again."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
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

    // MARK: - Download & Install

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

    private func installUpdate(dmgPath: URL, releaseURL: String) {
        let mountPoint = "/tmp/clawdagotchi-update-mount"
        let appDestination = Bundle.main.bundlePath

        shell("hdiutil detach '\(mountPoint)' -quiet 2>/dev/null || true")

        let mountResult = shell("hdiutil attach -nobrowse -quiet '\(dmgPath.path)' -mountpoint '\(mountPoint)'")
        guard mountResult == 0 else {
            openReleasesPage(releaseURL)
            return
        }

        let copyResult = shell("ditto '\(mountPoint)/Clawdagotchi.app' '\(appDestination)'")

        shell("hdiutil detach '\(mountPoint)' -quiet")

        guard copyResult == 0 else {
            openReleasesPage(releaseURL)
            return
        }

        try? FileManager.default.removeItem(at: dmgPath)

        let config = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: config) { _, _ in }

        NSApp.terminate(nil)
    }

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
}
