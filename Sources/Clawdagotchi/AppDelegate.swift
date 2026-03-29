import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppSettings.shared.applyDockPolicy()
    }

    func applicationWillTerminate(_ notification: Notification) {
        try? FileManager.default.removeItem(atPath: "/tmp/clawdagotchi.token")
    }

    func openSettingsFromKeyboard() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}
