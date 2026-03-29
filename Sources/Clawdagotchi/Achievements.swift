import Foundation

struct Achievement: Identifiable {
    let id: String
    let name: String
    let description: String
    let xpBonus: Int
    let check: @MainActor (AppSettings) -> Bool
}

@MainActor
final class AchievementManager {
    static let shared = AchievementManager()

    static let all: [Achievement] = [
        Achievement(id: "firstPoke", name: "First Poke", description: "Poke the crab for the first time", xpBonus: 5, check: { $0.totalPokes >= 1 }),
        Achievement(id: "firstFeed", name: "First Feed", description: "Feed the crab for the first time", xpBonus: 5, check: { $0.totalFeeds >= 1 }),
        Achievement(id: "firstPet", name: "First Pet", description: "Pet the crab for the first time", xpBonus: 5, check: { $0.totalPets >= 1 }),
        Achievement(id: "sessions10", name: "10 Sessions", description: "Complete 10 Claude sessions", xpBonus: 20, check: { $0.totalSessions >= 10 }),
        Achievement(id: "sessions50", name: "50 Sessions", description: "Complete 50 Claude sessions", xpBonus: 50, check: { $0.totalSessions >= 50 }),
        Achievement(id: "tools100", name: "100 Tools", description: "Use 100 tools", xpBonus: 30, check: { $0.totalToolUses >= 100 }),
        Achievement(id: "streak7", name: "Week Streak", description: "7-day login streak", xpBonus: 25, check: { $0.streak >= 7 }),
        Achievement(id: "streak30", name: "Month Streak", description: "30-day login streak", xpBonus: 100, check: { $0.streak >= 30 }),
        Achievement(id: "level5", name: "Halfway There", description: "Reach level 5", xpBonus: 25, check: { $0.level >= 5 }),
        Achievement(id: "level8", name: "Max Level", description: "Reach level 8", xpBonus: 50, check: { $0.level >= 8 }),
        Achievement(id: "poops25", name: "Clean Machine", description: "Clean 25 poops", xpBonus: 15, check: { $0.totalPoopsCleaned >= 25 }),
    ]

    func checkAchievements() -> [Achievement] {
        let settings = AppSettings.shared
        var unlocked = settings.unlockedAchievements
        var newlyUnlocked: [Achievement] = []

        for achievement in Self.all {
            if !unlocked.contains(achievement.id) && achievement.check(settings) {
                unlocked.insert(achievement.id)
                newlyUnlocked.append(achievement)
            }
        }

        if !newlyUnlocked.isEmpty {
            settings.unlockedAchievements = unlocked
        }

        return newlyUnlocked
    }
}
