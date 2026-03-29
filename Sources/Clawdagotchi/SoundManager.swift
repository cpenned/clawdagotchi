import AppKit

enum SoundAction: String, CaseIterable {
    case permissionAlert = "permissionAlert"
    case permissionApproved = "permissionApproved"
    case permissionDenied = "permissionDenied"
    case sessionDone = "sessionDone"
    case poke = "poke"
    case pet = "pet"

    var label: String {
        switch self {
        case .permissionAlert: "Permission requested"
        case .permissionApproved: "Permission approved"
        case .permissionDenied: "Permission denied"
        case .sessionDone: "Session complete"
        case .poke: "Poke the crab"
        case .pet: "Pet the crab"
        }
    }

    var defaultSound: String {
        switch self {
        case .permissionAlert: "Funk"
        case .permissionApproved: "Pop"
        case .permissionDenied: "Basso"
        case .sessionDone: "Glass"
        case .poke: "Frog"
        case .pet: "Purr"
        }
    }

    var settingsKey: String { "sound_\(rawValue)" }
}

let availableSounds = [
    "Basso", "Blow", "Bottle", "Frog", "Funk",
    "Glass", "Hero", "Morse", "Ping", "Pop",
    "Purr", "Sosumi", "Submarine", "Tink",
]

@MainActor
final class SoundManager {
    static let shared = SoundManager()
    private init() {}

    func soundName(for action: SoundAction) -> String {
        UserDefaults.standard.string(forKey: action.settingsKey) ?? action.defaultSound
    }

    func setSoundName(_ name: String, for action: SoundAction) {
        UserDefaults.standard.set(name, forKey: action.settingsKey)
    }

    func play(_ action: SoundAction) {
        let settings = AppSettings.shared
        guard settings.soundEnabled else { return }

        let name = soundName(for: action)
        guard let sound = NSSound(named: NSSound.Name(name)) else { return }
        sound.volume = settings.soundVolume
        sound.play()
    }

    func preview(_ name: String) {
        guard let sound = NSSound(named: NSSound.Name(name)) else { return }
        sound.volume = AppSettings.shared.soundVolume
        sound.play()
    }
}
