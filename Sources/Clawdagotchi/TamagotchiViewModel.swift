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

    static let levelThresholds = [0, 100, 350, 800, 1500, 2500, 4000, 6000]

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

    enum FunReaction: Equatable {
        case poke
        case pet
        case feed
    }

    private var sessions: [String: Session] = [:]
    private var server: HookServer?
    private var expiryTask: Task<Void, Never>?
    private var moodTask: Task<Void, Never>?
    private var permissionExpiryTask: Task<Void, Never>?
    private var lastInteractionTime: Date = Date()
    private var lastFedTime: Date = Date()
    private var lastPoopTime: Date = Date()

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

        // Also check for stale permissions (handled in terminal instead of Tamagotchi)
        permissionExpiryTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                self?.expireStalePermissions()
            }
        }
    }

    private func expireStalePermissions() {
        let cutoff = Date().addingTimeInterval(-30)
        let stale = permissionQueue.filter { $0.receivedAt < cutoff }
        for perm in stale {
            server?.respondToPermission(id: perm.id, decision: "deny", reason: "Timed out in Clawdagotchi")
        }
        let before = permissionQueue.count
        permissionQueue.removeAll { $0.receivedAt < cutoff }
        if permissionQueue.count != before {
            updateDisplayState()
        }
    }

    func stop() {
        server?.stop()
        expiryTask?.cancel()
        moodTask?.cancel()
        permissionExpiryTask?.cancel()
    }

    private func checkDailyLogin() {
        let today = Self.todayString()
        let settings = AppSettings.shared

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

        if settings.streak > 1 {
            greetingMessage = "\(Self.timeOfDayGreeting()) \(settings.streak) day streak!"
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
        // Hunger drains ~1% per 30s = empty in ~50 min
        // Happiness drains ~0.8% per 30s = empty in ~62 min
        hunger = max(0, hunger - 0.02)
        happiness = max(0, happiness - 0.016)

        guard displayState == .idle else {
            if moodState != .normal {
                withAnimation { moodState = .normal }
            }
            return
        }

        let now = Date()
        let sinceInteraction = now.timeIntervalSince(lastInteractionTime)
        let sinceFed = now.timeIntervalSince(lastFedTime)
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
        happiness = min(1, happiness + 0.15)

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
        Task {
            try? await Task.sleep(for: .seconds(0.8))
            funReaction = nil
        }
    }

    func feedCrab() {
        guard permissionQueue.isEmpty else { return }
        lastInteractionTime = Date()
        lastFedTime = Date()
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
        grantXP(1)
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            funReaction = nil
        }
    }

    func petCrab() {
        guard permissionQueue.isEmpty else { return }
        lastInteractionTime = Date()
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
        grantXP(1)
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            funReaction = nil
        }
    }

    // MARK: - XP & Level

    func resetProgress() {
        AppSettings.shared.xp = 0
        AppSettings.shared.level = 1
    }

    func grantXP(_ amount: Int) {
        AppSettings.shared.xp += amount
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

        lastInteractionTime = now
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
