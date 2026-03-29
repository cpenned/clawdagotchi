@preconcurrency import Network
import Foundation

struct HookEvent: Sendable {
    let event: String
    let sessionId: String
    let tool: String
}

private struct HookPayload: Decodable, Sendable {
    let event: String
    let session_id: String
    let tool: String?
}

final class HookServer: @unchecked Sendable {
    nonisolated(unsafe) private var listener: NWListener?
    private let queue = DispatchQueue(label: "com.claudetamagotchi.server")
    private let eventHandler: @MainActor @Sendable (HookEvent) -> Void

    init(onEvent: @escaping @MainActor @Sendable (HookEvent) -> Void) {
        self.eventHandler = onEvent
    }

    func start() {
        do {
            listener = try NWListener(using: .tcp, on: 7777)
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
                print("[HookServer] Listening on port 7777")
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
    }

    // MARK: - Connection handling

    private func handleConnection(_ conn: NWConnection) {
        conn.start(queue: queue)
        conn.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, error in
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
        guard parts.count >= 2, parts[0] == "POST", parts[1] == "/hook" else {
            respond(conn, status: "404 Not Found", body: #"{"error":"not found"}"#)
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

        let event = HookEvent(
            event: payload.event,
            sessionId: payload.session_id,
            tool: payload.tool ?? ""
        )

        let handler = self.eventHandler
        Task { @MainActor in
            handler(event)
        }

        respond(conn, status: "200 OK", body: #"{"ok":true}"#)
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
