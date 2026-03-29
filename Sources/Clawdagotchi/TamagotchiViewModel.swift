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

    func start() {
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

    // MARK: - Time of day greeting

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

    private func touchInteraction() {
        lastInteractionTime = Date()
        if moodState != .normal {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                moodState = .normal
            }
        }
    }

    private func updateMood() {
        guard displayState == .idle else {
            if moodState != .normal {
                withAnimation { moodState = .normal }
            }
            return
        }

        let now = Date()
        let sinceInteraction = now.timeIntervalSince(lastInteractionTime)
        let sinceFed = now.timeIntervalSince(lastFedTime)

        // Don't override pooping (it's a timed event)
        if moodState == .pooping { return }

        let newMood: MoodState
        if sinceInteraction > 480 {
            newMood = .angry
        } else if sinceFed > 300 {
            newMood = .hungry
        } else if sinceInteraction > 120 {
            newMood = .sleeping
        } else {
            // Random poop chance (~10% per check when idle+normal)
            if moodState == .normal && Int.random(in: 0..<10) == 0 {
                withAnimation { moodState = .pooping }
                Task { [weak self] in
                    try? await Task.sleep(for: .seconds(3))
                    if self?.moodState == .pooping {
                        withAnimation { self?.moodState = .normal }
                    }
                }
                return
            }
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
        touchInteraction()
        updateDisplayState()
    }

    func denyPermission() {
        guard let perm = pendingPermission else { return }
        server?.respondToPermission(id: perm.id, decision: "deny", reason: "Denied from Clawdagotchi")
        permissionQueue.removeFirst()
        SoundManager.shared.play(.permissionDenied)
        touchInteraction()
        updateDisplayState()
    }

    // MARK: - Fun interactions

    func pokeCrab() {
        guard permissionQueue.isEmpty else { return }
        touchInteraction()
        funReaction = .poke
        SoundManager.shared.play(.poke)
        Task {
            try? await Task.sleep(for: .seconds(0.8))
            funReaction = nil
        }
    }

    func feedCrab() {
        guard permissionQueue.isEmpty else { return }
        touchInteraction()
        lastFedTime = Date()
        funReaction = .feed
        SoundManager.shared.play(.pet)
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            funReaction = nil
        }
    }

    func petCrab() {
        guard permissionQueue.isEmpty else { return }
        touchInteraction()
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

        touchInteraction()

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
        touchInteraction()
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
