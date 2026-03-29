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

    enum FunReaction: Equatable {
        case poke
        case pet
        case feed
    }

    private var sessions: [String: Session] = [:]
    private var server: HookServer?
    private var expiryTask: Task<Void, Never>?
    private var moodTask: Task<Void, Never>?
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
    }

    func stop() {
        server?.stop()
        expiryTask?.cancel()
        moodTask?.cancel()
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
        updateDisplayState()
    }

    func denyPermission() {
        guard let perm = pendingPermission else { return }
        server?.respondToPermission(id: perm.id, decision: "deny", reason: "Denied from Clawdagotchi")
        permissionQueue.removeFirst()
        SoundManager.shared.play(.permissionDenied)
        lastInteractionTime = Date()
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
        }
        if moodState == .sleeping {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                moodState = .normal
            }
        }

        funReaction = .pet
        SoundManager.shared.play(.pet)
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            funReaction = nil
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

        switch event.event {
        case "PreToolUse":
            sessions[sessionId] = Session(state: .thinking, lastEventTime: now)

        case "PostToolUse":
            sessions[sessionId] = Session(state: .working, lastEventTime: now)

        case "Stop", "SubagentStop":
            sessions[sessionId] = Session(state: .done, lastEventTime: now)
            SoundManager.shared.play(.sessionDone)
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
