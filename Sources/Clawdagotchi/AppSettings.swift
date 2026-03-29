import SwiftUI

@MainActor
@Observable
final class AppSettings {
    static let shared = AppSettings()

    var showDockIcon: Bool {
        didSet { UserDefaults.standard.set(showDockIcon, forKey: "showDockIcon"); applyDockPolicy() }
    }
    var showMenubarIcon: Bool {
        didSet { UserDefaults.standard.set(showMenubarIcon, forKey: "showMenubarIcon") }
    }
    var showWidget: Bool {
        didSet { UserDefaults.standard.set(showWidget, forKey: "showWidget") }
    }
    var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled") }
    }
    var soundVolume: Float {
        didSet { UserDefaults.standard.set(soundVolume, forKey: "soundVolume") }
    }
    var shellStyle: ShellStyle {
        didSet { UserDefaults.standard.set(shellStyle.rawValue, forKey: "shellStyle") }
    }
    var widgetScale: Double {
        didSet { UserDefaults.standard.set(widgetScale, forKey: "widgetScale") }
    }

    private init() {
        let defaults = UserDefaults.standard
        defaults.register(defaults: [
            "showDockIcon": false,
            "showMenubarIcon": true,
            "showWidget": true,
            "soundEnabled": true,
            "soundVolume": Float(0.5),
            "shellStyle": ShellStyle.salmonPink.rawValue,
            "widgetScale": 1.0,
        ])
        self.showDockIcon = defaults.bool(forKey: "showDockIcon")
        self.showMenubarIcon = defaults.bool(forKey: "showMenubarIcon")
        self.showWidget = defaults.bool(forKey: "showWidget")
        self.soundEnabled = defaults.bool(forKey: "soundEnabled")
        self.soundVolume = defaults.float(forKey: "soundVolume")
        self.shellStyle = ShellStyle(rawValue: defaults.string(forKey: "shellStyle") ?? "") ?? .salmonPink
        self.widgetScale = defaults.double(forKey: "widgetScale")
    }

    func applyDockPolicy() {
        NSApp.setActivationPolicy(showDockIcon ? .regular : .accessory)
    }
}
