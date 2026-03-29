import Foundation
import SwiftUI

enum PetState: Equatable, Sendable {
    case idle
    case thinking
    case working
    case done
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

    private var sessions: [String: Session] = [:]
    private var server: HookServer?
    private var expiryTask: Task<Void, Never>?

    func start() {
        server = HookServer { [weak self] event in
            self?.handleEvent(event)
        }
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

    private func handleEvent(_ event: HookEvent) {
        let sessionId = event.sessionId
        let now = Date()

        switch event.event {
        case "PreToolUse":
            sessions[sessionId] = Session(state: .thinking, lastEventTime: now)

        case "PostToolUse":
            sessions[sessionId] = Session(state: .working, lastEventTime: now)

        case "Stop", "SubagentStop":
            sessions[sessionId] = Session(state: .done, lastEventTime: now)
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
