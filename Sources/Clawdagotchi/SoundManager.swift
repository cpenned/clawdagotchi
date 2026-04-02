import AppKit

enum SoundEntry: Codable, Hashable {
    case system(String)
    case custom(URL)

    var displayName: String {
        switch self {
        case .system(let name): name
        case .custom(let url): url.deletingPathExtension().lastPathComponent
        }
    }
}

enum SoundAction: String, CaseIterable {
    case permissionAlert = "permissionAlert"
    case permissionApproved = "permissionApproved"
    case permissionDenied = "permissionDenied"
    case sessionDone = "sessionDone"
    case poke = "poke"
    case feed = "feed"
    case pet = "pet"
    case levelUp = "levelUp"
    case simonCorrect = "simonCorrect"
    case simonWrong = "simonWrong"

    var label: String {
        switch self {
        case .permissionAlert: "Permission requested"
        case .permissionApproved: "Permission approved"
        case .permissionDenied: "Permission denied"
        case .sessionDone: "Session complete"
        case .poke: "Poke the crab"
        case .feed: "Feed the crab"
        case .pet: "Pet the crab"
        case .levelUp: "Level up"
        case .simonCorrect: "Simon correct"
        case .simonWrong: "Simon wrong"
        }
    }

    var defaultEntry: SoundEntry {
        switch self {
        case .permissionAlert: .system("Funk")
        case .permissionApproved: .system("Pop")
        case .permissionDenied: .system("Basso")
        case .sessionDone: .system("Glass")
        case .poke: .system("Frog")
        case .feed: .system("Bottle")
        case .pet: .system("Purr")
        case .levelUp: .system("Hero")
        case .simonCorrect: .system("Tink")
        case .simonWrong: .system("Basso")
        }
    }

    var settingsKey: String { "sound_\(rawValue)" }
}

@MainActor
final class SoundManager {
    static let shared = SoundManager()

    static let availableSounds = [
        "Basso", "Blow", "Bottle", "Frog", "Funk",
        "Glass", "Hero", "Morse", "Ping", "Pop",
        "Purr", "Sosumi", "Submarine", "Tink",
    ]

    private(set) var customSounds: [SoundEntry] = []

    private init() {
        loadCustomSounds()
    }

    // MARK: - Custom sounds persistence

    private func loadCustomSounds() {
        guard let data = UserDefaults.standard.data(forKey: "customSounds"),
              let decoded = try? JSONDecoder().decode([SoundEntry].self, from: data)
        else { return }
        customSounds = decoded
    }

    private func saveCustomSounds() {
        guard let data = try? JSONEncoder().encode(customSounds) else { return }
        UserDefaults.standard.set(data, forKey: "customSounds")
    }

    @discardableResult
    func addCustomSound(url: URL) -> SoundEntry {
        let entry = SoundEntry.custom(url)
        if !customSounds.contains(entry) {
            customSounds.append(entry)
            saveCustomSounds()
        }
        return entry
    }

    // MARK: - Per-action entry

    func soundEntry(for action: SoundAction) -> SoundEntry {
        guard let data = UserDefaults.standard.data(forKey: action.settingsKey),
              let entry = try? JSONDecoder().decode(SoundEntry.self, from: data)
        else { return action.defaultEntry }
        return entry
    }

    func setSoundEntry(_ entry: SoundEntry, for action: SoundAction) {
        guard let data = try? JSONEncoder().encode(entry) else { return }
        UserDefaults.standard.set(data, forKey: action.settingsKey)
    }

    // MARK: - Playback

    func play(_ action: SoundAction) {
        let settings = AppSettings.shared
        guard settings.soundEnabled else { return }
        preview(soundEntry(for: action))
    }

    func preview(_ entry: SoundEntry) {
        let sound: NSSound?
        switch entry {
        case .system(let name):
            sound = NSSound(named: NSSound.Name(name))
        case .custom(let url):
            sound = NSSound(contentsOf: url, byReference: false)
        }
        guard let sound else { return }
        sound.volume = AppSettings.shared.soundVolume
        sound.play()
    }
}
