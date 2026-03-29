import Foundation
import SwiftUI

enum PetState: Equatable, Sendable {
    case idle
    case thinking
    case working
    case done
    case permissionNeeded
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

    // Permission queue
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
    }

    func stop() {
        server?.stop()
        expiryTask?.cancel()
    }

    // MARK: - Permission actions

    func approvePermission() {
        guard let perm = pendingPermission else { return }
        server?.respondToPermission(id: perm.id, decision: "allow")
        permissionQueue.removeFirst()
        SoundManager.shared.play(.permissionApproved)
        updateDisplayState()
    }

    func denyPermission() {
        guard let perm = pendingPermission else { return }
        server?.respondToPermission(id: perm.id, decision: "deny", reason: "Denied from Clawdagotchi")
        permissionQueue.removeFirst()
        SoundManager.shared.play(.permissionDenied)
        updateDisplayState()
    }

    // MARK: - Fun interactions

    func pokeCrab() {
        guard permissionQueue.isEmpty else { return }
        funReaction = .poke
        SoundManager.shared.play(.poke)
        Task {
            try? await Task.sleep(for: .seconds(0.8))
            funReaction = nil
        }
    }

    func petCrab() {
        guard permissionQueue.isEmpty else { return }
        funReaction = .pet
        SoundManager.shared.play(.pet)
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            funReaction = nil
        }
    }

    func feedCrab() {
        guard permissionQueue.isEmpty else { return }
        funReaction = .feed
        SoundManager.shared.play(.pet)
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            funReaction = nil
        }
    }

    // MARK: - Event handling

    private func handleEvent(_ event: HookEvent) {
        let sessionId = event.sessionId
        let now = Date()

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
