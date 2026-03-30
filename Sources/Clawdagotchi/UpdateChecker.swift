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

    // MARK: - Download & Install (stubs — implemented in later tasks)

    private func downloadAndInstall(version: String, dmgURL: String, releaseURL: String) async {
        // Task 2
    }

    @discardableResult
    private func shell(_ command: String) -> Int32 {
        // Task 3
        return -1
    }
}
