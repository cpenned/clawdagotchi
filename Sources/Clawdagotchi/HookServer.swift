@preconcurrency import Network
import Foundation

struct HookEvent: Sendable {
    let event: String
    let sessionId: String
    let tool: String
    let toolInput: String
}

private struct HookPayload: Decodable, Sendable {
    let event: String
    let session_id: String
    let tool: String?
    let tool_input: String?
}

struct PendingPermission: Sendable, Identifiable {
    let id: String
    let sessionId: String
    let tool: String
    let toolInput: String
    let receivedAt: Date
}

final class HookServer: @unchecked Sendable {
    nonisolated(unsafe) private var listener: NWListener?
    private let queue = DispatchQueue(label: "com.claudetamagotchi.server")
    private let eventHandler: @MainActor @Sendable (HookEvent) -> Void
    private let permissionHandler: @MainActor @Sendable (PendingPermission) -> Void

    // Held connections for permission responses, keyed by permission ID
    private var pendingConnections: [String: NWConnection] = [:]
    private let lock = NSLock()

    init(
        onEvent: @escaping @MainActor @Sendable (HookEvent) -> Void,
        onPermission: @escaping @MainActor @Sendable (PendingPermission) -> Void
    ) {
        self.eventHandler = onEvent
        self.permissionHandler = onPermission
    }

    private(set) var authToken: String = ""

    func start() {
        // Generate auth token and write to temp file
        authToken = UUID().uuidString
        let tokenPath = "/tmp/clawdagotchi.token"
        try? authToken.write(toFile: tokenPath, atomically: true, encoding: .utf8)
        try? FileManager.default.setAttributes(
            [.posixPermissions: 0o600], ofItemAtPath: tokenPath
        )

        // Bind to localhost only
        let params = NWParameters.tcp
        params.requiredLocalEndpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host("127.0.0.1"),
            port: 7777
        )

        do {
            listener = try NWListener(using: params)
        } catch {
            print("[HookServer] Failed to create listener: \(error)")
            return
        }

        listener?.newConnectionHandler = { [weak self] conn in
            self?.handleConnection(conn)
        }

        listener?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("[HookServer] Listening on 127.0.0.1:7777")
            case .failed(let err):
                print("[HookServer] Failed: \(err)")
            default:
                break
            }
        }

        listener?.start(queue: queue)
    }

    func stop() {
        listener?.cancel()
        listener = nil
        lock.lock()
        for conn in pendingConnections.values { conn.cancel() }
        pendingConnections.removeAll()
        lock.unlock()
    }

    func respondToPermission(id: String, decision: String, reason: String? = nil) {
        lock.lock()
        guard let conn = pendingConnections.removeValue(forKey: id) else {
            lock.unlock()
            return
        }
        lock.unlock()

        var responseDict: [String: Any] = [
            "hookSpecificOutput": [
                "hookEventName": "PermissionRequest",
                "decision": [
                    "behavior": decision
                ] as [String: Any]
            ] as [String: Any]
        ]

        if decision == "deny", let reason {
            var output = responseDict["hookSpecificOutput"] as! [String: Any]
            var dec = output["decision"] as! [String: Any]
            dec["message"] = reason
            output["decision"] = dec
            responseDict["hookSpecificOutput"] = output
        }

        let body: String
        if let data = try? JSONSerialization.data(withJSONObject: responseDict),
           let str = String(data: data, encoding: .utf8) {
            body = str
        } else {
            body = #"{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"\#(decision)"}}}"#
        }

        respond(conn, status: "200 OK", body: body)
    }

    // MARK: - Connection handling

    private func handleConnection(_ conn: NWConnection) {
        conn.start(queue: queue)
        conn.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, _ in
            if let data {
                self?.processHTTP(data, connection: conn)
            } else {
                conn.cancel()
            }
        }
    }

    private func processHTTP(_ data: Data, connection conn: NWConnection) {
        guard let raw = String(data: data, encoding: .utf8) else {
            respond(conn, status: "400 Bad Request", body: #"{"error":"bad encoding"}"#)
            return
        }

        let lines = raw.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else {
            respond(conn, status: "400 Bad Request", body: #"{"error":"no request line"}"#)
            return
        }

        let parts = requestLine.split(separator: " ", maxSplits: 2)
        guard parts.count >= 2, parts[0] == "POST" else {
            respond(conn, status: "404 Not Found", body: #"{"error":"not found"}"#)
            return
        }

        let path = String(parts[1])

        // Validate auth token
        let authHeader = lines.first(where: { $0.lowercased().hasPrefix("authorization: bearer ") })
        let token = authHeader.map { String($0.dropFirst("authorization: bearer ".count)) }
        if token != authToken {
            respond(conn, status: "403 Forbidden", body: #"{"error":"invalid token"}"#)
            return
        }

        guard let bodyRange = raw.range(of: "\r\n\r\n") else {
            respond(conn, status: "400 Bad Request", body: #"{"error":"no body"}"#)
            return
        }

        let bodyStr = String(raw[bodyRange.upperBound...])
        guard let bodyData = bodyStr.data(using: .utf8),
              let payload = try? JSONDecoder().decode(HookPayload.self, from: bodyData) else {
            respond(conn, status: "400 Bad Request", body: #"{"error":"invalid json"}"#)
            return
        }

        switch path {
        case "/hook":
            let event = HookEvent(
                event: payload.event,
                sessionId: payload.session_id,
                tool: payload.tool ?? "",
                toolInput: payload.tool_input ?? ""
            )
            let handler = self.eventHandler
            Task { @MainActor in handler(event) }
            respond(conn, status: "200 OK", body: #"{"ok":true}"#)

        case "/permission":
            let permId = UUID().uuidString
            let permission = PendingPermission(
                id: permId,
                sessionId: payload.session_id,
                tool: payload.tool ?? "unknown",
                toolInput: payload.tool_input ?? "",
                receivedAt: Date()
            )

            lock.lock()
            pendingConnections[permId] = conn
            lock.unlock()

            let handler = self.permissionHandler
            Task { @MainActor in handler(permission) }
            // Don't respond — hold connection open until user decides

        default:
            respond(conn, status: "404 Not Found", body: #"{"error":"not found"}"#)
        }
    }

    private func respond(_ conn: NWConnection, status: String, body: String) {
        let header = "HTTP/1.1 \(status)\r\nContent-Type: application/json\r\nContent-Length: \(body.utf8.count)\r\nConnection: close\r\n\r\n"
        let response = header + body
        conn.send(
            content: response.data(using: .utf8),
            contentContext: .finalMessage,
            isComplete: true,
            completion: .contentProcessed { _ in conn.cancel() }
        )
    }
}
