import SwiftUI

enum FloatPolicy: String, CaseIterable, Sendable {
    case always
    case permissionOnly
    case never

    var displayName: String {
        switch self {
        case .always: "Always"
        case .permissionOnly: "Only during permission requests"
        case .never: "Never"
        }
    }
}

@MainActor
@Observable
final class AppSettings {
    static let shared = AppSettings()

    var showDockIcon: Bool {
        didSet { UserDefaults.standard.set(showDockIcon, forKey: "showDockIcon"); applyDockPolicy() }
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
    var floatPolicy: FloatPolicy {
        didSet { UserDefaults.standard.set(floatPolicy.rawValue, forKey: "floatPolicy") }
    }
    var botName: String {
        didSet { UserDefaults.standard.set(botName, forKey: "botName") }
    }
    var useCustomCrabColor: Bool {
        didSet { UserDefaults.standard.set(useCustomCrabColor, forKey: "useCustomCrabColor") }
    }
    var xp: Int {
        didSet { UserDefaults.standard.set(xp, forKey: "xp") }
    }
    var level: Int {
        didSet { UserDefaults.standard.set(level, forKey: "level") }
    }
    var backgroundTheme: BackgroundTheme {
        didSet { UserDefaults.standard.set(backgroundTheme.rawValue, forKey: "backgroundTheme") }
    }
    var seasonalAccessories: Bool {
        didSet { UserDefaults.standard.set(seasonalAccessories, forKey: "seasonalAccessories") }
    }

    // Streak
    var streak: Int {
        didSet { UserDefaults.standard.set(streak, forKey: "streak") }
    }
    var lastLoginDate: String {
        didSet { UserDefaults.standard.set(lastLoginDate, forKey: "lastLoginDate") }
    }
    var birthDate: String {
        didSet { UserDefaults.standard.set(birthDate, forKey: "birthDate") }
    }

    // Lifetime stats
    var totalSessions: Int {
        didSet { UserDefaults.standard.set(totalSessions, forKey: "totalSessions") }
    }
    var totalToolUses: Int {
        didSet { UserDefaults.standard.set(totalToolUses, forKey: "totalToolUses") }
    }
    var totalPermissionsApproved: Int {
        didSet { UserDefaults.standard.set(totalPermissionsApproved, forKey: "totalPermissionsApproved") }
    }
    var totalPermissionsDenied: Int {
        didSet { UserDefaults.standard.set(totalPermissionsDenied, forKey: "totalPermissionsDenied") }
    }
    var totalPokes: Int {
        didSet { UserDefaults.standard.set(totalPokes, forKey: "totalPokes") }
    }
    var totalFeeds: Int {
        didSet { UserDefaults.standard.set(totalFeeds, forKey: "totalFeeds") }
    }
    var totalPets: Int {
        didSet { UserDefaults.standard.set(totalPets, forKey: "totalPets") }
    }
    var totalPoopsCleaned: Int {
        didSet { UserDefaults.standard.set(totalPoopsCleaned, forKey: "totalPoopsCleaned") }
    }
    var unlockedAchievements: Set<String> {
        didSet {
            let array = Array(unlockedAchievements)
            if let data = try? JSONEncoder().encode(array) {
                UserDefaults.standard.set(String(data: data, encoding: .utf8), forKey: "unlockedAchievements")
            }
        }
    }

    var activeCrabColor: Color {
        useCustomCrabColor ? shellStyle.crabColor : Color(red: 0xD9 / 255.0, green: 0x77 / 255.0, blue: 0x57 / 255.0)
    }

    private init() {
        let defaults = UserDefaults.standard
        defaults.register(defaults: [
            "showDockIcon": false,
            "showWidget": true,
            "soundEnabled": true,
            "soundVolume": Float(0.5),
            "shellStyle": ShellStyle.salmonPink.rawValue,
            "widgetScale": 1.0,
            "floatPolicy": FloatPolicy.always.rawValue,
            "botName": "Clawd",
            "useCustomCrabColor": true,
            "xp": 0,
            "level": 1,
            "backgroundTheme": BackgroundTheme.none.rawValue,
            "seasonalAccessories": true,
            "streak": 0,
            "lastLoginDate": "",
            "birthDate": "",
            "totalSessions": 0,
            "totalToolUses": 0,
            "totalPermissionsApproved": 0,
            "totalPermissionsDenied": 0,
            "totalPokes": 0,
            "totalFeeds": 0,
            "totalPets": 0,
            "totalPoopsCleaned": 0,
            "unlockedAchievements": "[]",
        ])
        self.showDockIcon = defaults.bool(forKey: "showDockIcon")
        self.showWidget = defaults.bool(forKey: "showWidget")
        self.soundEnabled = defaults.bool(forKey: "soundEnabled")
        self.soundVolume = defaults.float(forKey: "soundVolume")
        self.shellStyle = ShellStyle(rawValue: defaults.string(forKey: "shellStyle") ?? "") ?? .salmonPink
        self.widgetScale = defaults.double(forKey: "widgetScale")
        self.floatPolicy = FloatPolicy(rawValue: defaults.string(forKey: "floatPolicy") ?? "") ?? .always
        self.botName = defaults.string(forKey: "botName") ?? "Clawd"
        self.useCustomCrabColor = defaults.bool(forKey: "useCustomCrabColor")
        self.xp = defaults.integer(forKey: "xp")
        self.level = defaults.integer(forKey: "level")
        self.backgroundTheme = BackgroundTheme(rawValue: defaults.string(forKey: "backgroundTheme") ?? "") ?? .none
        self.seasonalAccessories = defaults.bool(forKey: "seasonalAccessories")
        self.streak = defaults.integer(forKey: "streak")
        self.lastLoginDate = defaults.string(forKey: "lastLoginDate") ?? ""
        self.birthDate = defaults.string(forKey: "birthDate") ?? ""
        self.totalSessions = defaults.integer(forKey: "totalSessions")
        self.totalToolUses = defaults.integer(forKey: "totalToolUses")
        self.totalPermissionsApproved = defaults.integer(forKey: "totalPermissionsApproved")
        self.totalPermissionsDenied = defaults.integer(forKey: "totalPermissionsDenied")
        self.totalPokes = defaults.integer(forKey: "totalPokes")
        self.totalFeeds = defaults.integer(forKey: "totalFeeds")
        self.totalPets = defaults.integer(forKey: "totalPets")
        self.totalPoopsCleaned = defaults.integer(forKey: "totalPoopsCleaned")
        if let str = defaults.string(forKey: "unlockedAchievements"),
           let data = str.data(using: .utf8),
           let array = try? JSONDecoder().decode([String].self, from: data) {
            self.unlockedAchievements = Set(array)
        } else {
            self.unlockedAchievements = []
        }
    }

    var birthDateFormatted: String {
        guard !birthDate.isEmpty else { return "Unknown" }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let date = f.date(from: birthDate) else { return birthDate }
        let display = DateFormatter()
        display.dateStyle = .long
        return display.string(from: date)
    }

    var ageInDays: Int {
        guard !birthDate.isEmpty else { return 0 }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let date = f.date(from: birthDate) else { return 0 }
        return Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
    }

    func applyDockPolicy() {
        NSApp.setActivationPolicy(showDockIcon ? .regular : .accessory)
    }
}
