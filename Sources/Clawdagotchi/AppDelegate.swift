import AppKit

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

        NSApp.activate(ignoringOtherApps: true)
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
