import AppKit

enum SoundEffect: String {
    case permissionAlert = "Funk"
    case permissionApproved = "Pop"
    case permissionDenied = "Basso"
    case sessionDone = "Glass"
    case poke = "Frog"
    case pet = "Purr"
}

@MainActor
final class SoundManager {
    static let shared = SoundManager()
    private init() {}

    func play(_ effect: SoundEffect) {
        let settings = AppSettings.shared
        guard settings.soundEnabled else { return }

        guard let sound = NSSound(named: NSSound.Name(effect.rawValue)) else { return }
        sound.volume = settings.soundVolume
        sound.play()
    }
}
