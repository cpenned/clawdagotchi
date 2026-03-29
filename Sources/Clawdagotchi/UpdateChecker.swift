import Foundation
import AppKit

@MainActor
final class UpdateChecker {
    static let shared = UpdateChecker()
    private let repo = "cpenned/clawdagotchi"
    private let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

    private init() {}

    func checkOnLaunch() {
        Task {
            // Wait a few seconds so the app settles
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

            if isNewer(latestVersion, than: currentVersion) {
                showUpdateAvailable(version: latestVersion, url: htmlURL)
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

    private func showUpdateAvailable(version: String, url: String) {
        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText = "Clawdagotchi v\(version) is available. You're running v\(currentVersion)."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Download")
        alert.addButton(withTitle: "Later")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let downloadURL = URL(string: url) {
                NSWorkspace.shared.open(downloadURL)
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
}
