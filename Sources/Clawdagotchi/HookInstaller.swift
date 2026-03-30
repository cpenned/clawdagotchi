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
