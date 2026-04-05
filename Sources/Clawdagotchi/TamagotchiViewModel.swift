import Foundation
import SwiftUI

enum PetState: Equatable, Sendable {
    case idle
    case thinking
    case working
    case done
    case permissionNeeded
}

enum MoodState: Equatable, Sendable {
    case normal
    case sleeping
    case hungry
    case angry
    case pooping
}

@MainActor
@Observable
final class TamagotchiViewModel {
    static var shared: TamagotchiViewModel?

    struct Session: Sendable {
        var state: PetState
        var lastEventTime: Date
    }

    private(set) var displayState: PetState = .idle
    private(set) var activeSessionCount: Int = 0
    private(set) var lastToolUsed: String = ""
    private(set) var funReaction: FunReaction?
    private(set) var moodState: MoodState = .normal
    private(set) var greetingMessage: String = ""
    private(set) var poopCount: Int = 0
    private(set) var hunger: Double = 1.0     // 1.0 = full, 0.0 = starving
    private(set) var happiness: Double = 1.0  // 1.0 = happy, 0.0 = miserable

    private(set) var permissionQueue: [PendingPermission] = []
    var pendingPermission: PendingPermission? { permissionQueue.first }
    var pendingPermissionCount: Int { permissionQueue.count }

    private(set) var justLeveledUp: Bool = false
    private(set) var isDead: Bool = false
    private(set) var deathStats: DeathStats? = nil

    static let levelThresholds = [0, 200, 700, 1600, 3000, 5000, 8000, 12000]

    var currentLevel: Int { AppSettings.shared.level }
    var currentXP: Int { AppSettings.shared.xp }
    var xpForNextLevel: Int {
        let thresholds = Self.levelThresholds
        if currentLevel >= thresholds.count { return thresholds.last! }
        return thresholds[currentLevel]
    }
    var xpProgress: Double {
        let thresholds = Self.levelThresholds
        guard currentLevel >= 1 else { return 0 }
        if currentLevel >= thresholds.count { return 1.0 }
        let prevThreshold = currentLevel > 1 ? thresholds[currentLevel - 1] : 0
        let nextThreshold = thresholds[currentLevel]
        let range = nextThreshold - prevThreshold
        guard range > 0 else { return 1.0 }
        return Double(currentXP - prevThreshold) / Double(range)
    }

    struct DeathStats: Sendable {
        let name: String
        let days: Int
        let level: Int
        let xp: Int
    }

    enum FunReaction: Equatable {
        case poke
        case pet
        case feed
        case randomEvent(String)
    }

    private(set) var simonSaysActive: Bool = false
    private(set) var simonPromptActive: Bool = false
    private(set) var simonPattern: [Int] = []
    private(set) var simonStep: Int = 0
    private(set) var simonShowingPattern: Bool = false
    private(set) var simonHighlight: Int? = nil
    private var simonLength: Int = 3
    private var simonPromptTask: Task<Void, Never>?

    private var sessions: [String: Session] = [:]
    private var server: HookServer?
    private var expiryTask: Task<Void, Never>?
    private var moodTask: Task<Void, Never>?
    private var lastInteractionTime: Date = Date()
    private var lastFedTime: Date = Date()
    private var lastPoopTime: Date = Date()
    private var lastRandomEventTime: Date = Date()

    func start() {
        Self.shared = self
        server = HookServer(
            onEvent: { [weak self] event in self?.handleEvent(event) },
            onPermission: { [weak self] perm in self?.handlePermission(perm) }
        )
        server?.start()

        expiryTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(10))
                self?.expireStaleSessions()
            }
        }

        moodTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                self?.updateMood()
            }
        }

        greetingMessage = Self.timeOfDayGreeting()
        checkDailyLogin()
        checkForDeath()
    }

    func stop() {
        server?.stop()
        expiryTask?.cancel()
        moodTask?.cancel()
    }

    private func checkDailyLogin() {
        let today = Self.todayString()
        let settings = AppSettings.shared

        // Set birth date on first ever launch
        if AppSettings.shared.birthDate.isEmpty {
            AppSettings.shared.birthDate = Self.todayString()
        }

        if settings.lastLoginDate == today {
            return
        }

        let yesterday = Self.yesterdayString()
        if settings.lastLoginDate == yesterday {
            settings.streak += 1
        } else if settings.lastLoginDate.isEmpty {
            settings.streak = 1
        } else {
            settings.streak = 1
        }

        settings.lastLoginDate = today

        let bonusXP = min(5 + settings.streak, 25)
        grantXP(bonusXP)
        checkAndNotifyAchievements()

        if settings.streak > 1 {
            greetingMessage = "\(Self.timeOfDayGreeting()) \(settings.streak) day streak!"
        }

        // Check for birthday
        let birth = AppSettings.shared.birthDate
        if !birth.isEmpty {
            let birthMD = String(birth.dropFirst(5))  // "MM-dd"
            let todayMD = String(Self.todayString().dropFirst(5))
            if birthMD == todayMD && AppSettings.shared.ageInDays > 0 {
                greetingMessage = "happy birthday, \(AppSettings.shared.botName)!"
                grantXP(50)
            }
        }
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static func todayString() -> String {
        dateFormatter.string(from: Date())
    }

    private static func yesterdayString() -> String {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        return dateFormatter.string(from: yesterday)
    }

    private static func timeOfDayGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "good morning!"
        case 12..<17: return "good afternoon!"
        case 17..<21: return "good evening!"
        default: return "sleepy time..."
        }
    }

    // MARK: - Death

    private func checkForDeath() {
        let settings = AppSettings.shared
        let lastActivity = settings.lastClaudeActivityTimestamp
        guard lastActivity > 0, settings.deathThreshold > 0 else { return }
        let elapsed = Date().timeIntervalSince1970 - lastActivity
        if elapsed > settings.deathThreshold {
            isDead = true
            deathStats = DeathStats(
                name: settings.botName,
                days: settings.ageInDays,
                level: settings.level,
                xp: settings.xp
            )
        }
    }

    // MARK: - Mood system

    func previewMood(_ mood: MoodState) {
        withAnimation(.easeInOut(duration: 0.3)) {
            moodState = mood
            if mood == .pooping { poopCount += 1 }
        }
        Task {
            try? await Task.sleep(for: .seconds(4))
            withAnimation(.easeInOut(duration: 0.3)) {
                moodState = .normal
            }
        }
    }

    private func updateMood() {
        // Stats decay over time (every 30s tick)
        // Hunger drains ~0.002 per 30s = empty in ~4 hours
        // Happiness drains ~0.0015 per 30s = empty in ~5.5 hours
        hunger = max(0, hunger - Double.random(in: 0.0015...0.0025))
        happiness = max(0, happiness - Double.random(in: 0.001...0.002))

        guard displayState == .idle else {
            if moodState != .normal {
                withAnimation { moodState = .normal }
            }
            return
        }

        let now = Date()
        let sinceInteraction = now.timeIntervalSince(lastInteractionTime)
        let sincePoop = now.timeIntervalSince(lastPoopTime)

        // Don't override pooping animation or states needing specific actions
        if moodState == .pooping { return }
        if moodState == .angry || moodState == .hungry { return }

        // Periodic poop every ~15 min
        if sincePoop > 900 {
            lastPoopTime = now
            withAnimation { moodState = .pooping }
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(3))
                guard let self else { return }
                if self.moodState == .pooping {
                    withAnimation { self.moodState = .normal }
                }
                withAnimation { self.poopCount += 1 }
            }
            return
        }

        let newMood: MoodState
        if happiness <= 0 {
            newMood = .angry
        } else if hunger <= 0.15 {
            newMood = .hungry
        } else if sinceInteraction > 120 {
            newMood = .sleeping
        } else {
            newMood = .normal
        }

        if newMood != moodState {
            withAnimation(.easeInOut(duration: 0.5)) {
                moodState = newMood
            }
        }

        if displayState == .idle && moodState == .normal && !simonSaysActive && !simonPromptActive && Int.random(in: 0..<20) == 0 {
            promptSimonSays()
        }

        let sinceLastEvent = Date().timeIntervalSince(lastRandomEventTime)
        if displayState == .idle && sinceLastEvent > 300 && !simonSaysActive && Int.random(in: 0..<33) == 0 {
            triggerRandomEvent()
        }
    }

    // MARK: - Permission actions

    func approvePermission() {
        guard let perm = pendingPermission else { return }
        server?.respondToPermission(id: perm.id, decision: "allow")
        permissionQueue.removeFirst()
        SoundManager.shared.play(.permissionApproved)
        lastInteractionTime = Date()
        AppSettings.shared.totalPermissionsApproved += 1
        grantXP(5)
        updateDisplayState()
    }

    func denyPermission() {
        guard let perm = pendingPermission else { return }
        server?.respondToPermission(id: perm.id, decision: "deny", reason: "Denied from Clawdagotchi")
        permissionQueue.removeFirst()
        SoundManager.shared.play(.permissionDenied)
        lastInteractionTime = Date()
        AppSettings.shared.totalPermissionsDenied += 1
        grantXP(3)
        updateDisplayState()
    }

    // MARK: - Fun interactions (each clears a specific mood)

    func pokeCrab() {
        guard permissionQueue.isEmpty else { return }
        lastInteractionTime = Date()

        // Poke clears: angry, sleeping
        if moodState == .angry || moodState == .sleeping {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                moodState = .normal
            }
        }

        funReaction = .poke
        SoundManager.shared.play(.poke)
        AppSettings.shared.totalPokes += 1
        grantXP(1)
        checkAndNotifyAchievements()
        Task {
            try? await Task.sleep(for: .seconds(0.8))
            funReaction = nil
        }
    }

    func feedCrab() {
        guard permissionQueue.isEmpty else { return }
        lastInteractionTime = Date()
        lastFedTime = Date()
        let wasAlreadyFull = hunger >= 1.0
        hunger = min(1, hunger + 0.35)

        // Feed clears: hungry, sleeping
        if moodState == .hungry || moodState == .sleeping {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                moodState = .normal
            }
        }

        funReaction = .feed
        SoundManager.shared.play(.feed)
        AppSettings.shared.totalFeeds += 1
        if !wasAlreadyFull { grantXP(1) }
        checkAndNotifyAchievements()
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            funReaction = nil
        }
    }

    func petCrab() {
        guard permissionQueue.isEmpty else { return }
        lastInteractionTime = Date()
        let wasAlreadyFull = happiness >= 1.0
        happiness = min(1, happiness + 0.25)

        // Pet clears: one poop, sleeping
        if poopCount > 0 {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                poopCount -= 1
            }
            AppSettings.shared.totalPoopsCleaned += 1
        }
        if moodState == .sleeping {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                moodState = .normal
            }
        }

        funReaction = .pet
        SoundManager.shared.play(.pet)
        AppSettings.shared.totalPets += 1
        if !wasAlreadyFull { grantXP(1) }
        checkAndNotifyAchievements()
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            funReaction = nil
        }
    }

    // MARK: - Achievements

    private func checkAndNotifyAchievements() {
        let newAchievements = AchievementManager.shared.checkAchievements()
        for achievement in newAchievements {
            grantXP(achievement.xpBonus)
            funReaction = .randomEvent("\(achievement.name)!")
            Task {
                try? await Task.sleep(for: .seconds(2.0))
                funReaction = nil
            }
        }
    }

    // MARK: - Simon Says

    func startSimonSays() {
        guard !simonSaysActive, displayState == .idle, permissionQueue.isEmpty else { return }
        simonSaysActive = true
        simonStep = 0
        simonPattern = (0..<simonLength).map { _ in Int.random(in: 0...2) }
        simonShowingPattern = true
        showSimonPattern()
    }

    private func showSimonPattern() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.5))
            for button in simonPattern {
                guard simonSaysActive else { return }
                simonHighlight = button
                SoundManager.shared.play(.poke)
                try? await Task.sleep(for: .seconds(0.4))
                simonHighlight = nil
                try? await Task.sleep(for: .seconds(0.2))
            }
            simonShowingPattern = false
        }
    }

    func simonInput(_ button: Int) {
        guard simonSaysActive, !simonShowingPattern else { return }
        if button == simonPattern[simonStep] {
            simonStep += 1
            SoundManager.shared.play(.simonCorrect)
            if simonStep >= simonPattern.count {
                let reward = 5 * simonPattern.count
                grantXP(reward)
                simonSaysActive = false
                simonLength = min(simonLength + 1, 7)
                funReaction = .randomEvent("nice! +\(reward)xp")
                Task { try? await Task.sleep(for: .seconds(1.5)); funReaction = nil }
            }
        } else {
            SoundManager.shared.play(.simonWrong)
            simonSaysActive = false
            simonLength = 3
            funReaction = .randomEvent("oops!")
            Task { try? await Task.sleep(for: .seconds(1.5)); funReaction = nil }
        }
    }

    func cancelSimonSays() {
        simonSaysActive = false
        simonShowingPattern = false
        simonHighlight = nil
        simonLength = 3
    }

    private func promptSimonSays() {
        simonPromptActive = true
        simonPromptTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(15))
            guard let self, !Task.isCancelled else { return }
            self.simonPromptActive = false
        }
    }

    func acceptSimonPrompt() {
        simonPromptTask?.cancel()
        simonPromptTask = nil
        simonPromptActive = false
        startSimonSays()
    }

    func declineSimonPrompt() {
        simonPromptTask?.cancel()
        simonPromptTask = nil
        simonPromptActive = false
    }

    // MARK: - Random Events

    private func triggerRandomEvent() {
        lastRandomEventTime = Date()
        let events: [(String, Int)] = [
            ("caught a bug!", 15),
            ("found treasure!", 25),
            ("make a wish!", 10),
            ("made a friend!", 10),
            ("power nap!", 5),
        ]
        let (message, xp) = events.randomElement()!
        grantXP(xp)
        funReaction = .randomEvent("\(message) +\(xp)xp")
        Task {
            try? await Task.sleep(for: .seconds(2.0))
            funReaction = nil
        }
    }

    // MARK: - XP & Level

    func resetProgress() {
        AppSettings.shared.xp = 0
        AppSettings.shared.level = 1
    }

    func rebirth(newName: String) {
        let settings = AppSettings.shared
        settings.xp = 0
        settings.level = 1
        settings.birthDate = Self.todayString()
        settings.streak = 0
        settings.lastLoginDate = Self.todayString()
        settings.botName = newName.isEmpty ? "Clawd" : newName
        settings.lastClaudeActivityTimestamp = 0
        settings.deathThreshold = 0
        isDead = false
        deathStats = nil
    }

    func grantXP(_ amount: Int) {
        AppSettings.shared.xp += amount
        AppSettings.shared.totalXPEarned += amount
        checkLevelUp()
    }

    private func checkLevelUp() {
        let thresholds = Self.levelThresholds
        var newLevel = AppSettings.shared.level
        while newLevel < thresholds.count && AppSettings.shared.xp >= thresholds[newLevel] {
            newLevel += 1
        }
        if newLevel > AppSettings.shared.level {
            AppSettings.shared.level = newLevel
            SoundManager.shared.play(.levelUp)
            justLeveledUp = true
            Task {
                try? await Task.sleep(for: .seconds(3))
                justLeveledUp = false
            }
        }
    }

    // MARK: - Event handling

    private func handleEvent(_ event: HookEvent) {
        let sessionId = event.sessionId
        let now = Date()

        if simonSaysActive { cancelSimonSays() }
        if simonPromptActive { declineSimonPrompt() }

        lastInteractionTime = now
        let settings = AppSettings.shared
        settings.lastClaudeActivityTimestamp = now.timeIntervalSince1970
        if settings.deathThreshold == 0 {
            settings.deathThreshold = Double.random(in: 43200...86400)
        }
        // Claude activity clears all moods
        if moodState != .normal {
            withAnimation { moodState = .normal }
        }

        if !event.tool.isEmpty {
            lastToolUsed = event.tool
        }

        // If we get an event for a session that has a pending permission,
        // it was handled elsewhere (terminal) — clear it
        permissionQueue.removeAll { $0.sessionId == sessionId }

        switch event.event {
        case "PreToolUse":
            sessions[sessionId] = Session(state: .thinking, lastEventTime: now)

        case "PostToolUse":
            sessions[sessionId] = Session(state: .working, lastEventTime: now)
            AppSettings.shared.totalToolUses += 1
            grantXP(2)

        case "Stop", "SubagentStop":
            sessions[sessionId] = Session(state: .done, lastEventTime: now)
            AppSettings.shared.totalSessions += 1
            SoundManager.shared.play(.sessionDone)
            grantXP(10)
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(2))
                self?.sessions.removeValue(forKey: sessionId)
                self?.updateDisplayState()
            }

        default:
            return
        }

        checkAndNotifyAchievements()
        updateDisplayState()
    }

    private func handlePermission(_ perm: PendingPermission) {
        SoundManager.shared.play(.permissionAlert)
        lastInteractionTime = Date()
        permissionQueue.append(perm)
        sessions[perm.sessionId] = Session(state: .permissionNeeded, lastEventTime: perm.receivedAt)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            displayState = .permissionNeeded
        }
        activeSessionCount = sessions.count
    }

    private func expireStaleSessions() {
        let cutoff = Date().addingTimeInterval(-60)
        let before = sessions.count
        sessions = sessions.filter { $0.value.lastEventTime > cutoff }
        if sessions.count != before {
            updateDisplayState()
        }
    }

    private func updateDisplayState() {
        activeSessionCount = sessions.count

        if !permissionQueue.isEmpty {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                displayState = .permissionNeeded
            }
            return
        }

        if sessions.isEmpty {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                displayState = .idle
            }
            return
        }

        let states = sessions.values.map(\.state)
        let newState: PetState
        if states.contains(.thinking) {
            newState = .thinking
        } else if states.contains(.working) {
            newState = .working
        } else {
            newState = .done
        }

        if newState != displayState {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                displayState = newState
            }
        }
    }
}
