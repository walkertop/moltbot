import Foundation
import UIKit

/// Log entry from gateway server
struct LogEntry: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let level: LogLevel
    let message: String
    let source: String?

    enum LogLevel: String {
        case info = "INFO"
        case debug = "DEBUG"
        case warning = "WARN"
        case error = "ERROR"
        case success = "SUCCESS"

        var color: String {
            switch self {
            case .info: "#8E8E93"
            case .debug: "#5AC8FA"
            case .warning: "#FF9500"
            case .error: "#FF3B30"
            case .success: "#30D158"
            }
        }
    }
}

/// Gateway connection state
enum GatewayConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case error(String)

    var displayName: String {
        switch self {
        case .disconnected: "Disconnected"
        case .connecting: "Connecting..."
        case .connected: "Connected"
        case .error(let msg): "Error: \(msg)"
        }
    }
}

/// Gateway service for WebSocket communication with moltbot server
@MainActor
@Observable
final class GatewayService {
    static let shared = GatewayService()

    // Connection state
    var connectionState: GatewayConnectionState = .disconnected
    var serverURL: URL?

    // Terminal state
    var logs: [LogEntry] = []
    var isProcessingCommand = false
    var currentCommand: String?

    // WebSocket
    private var webSocket: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var receiveTask: Task<Void, Never>?
    private var pingTask: Task<Void, Never>?
    private var requestId = 0

    // Pending requests
    private var pendingRequests: [String: CheckedContinuation<Data, Error>] = [:]

    private init() {}

    // MARK: - Connection

    func connect(to url: URL) async {
        guard connectionState != .connecting else { return }

        serverURL = url
        connectionState = .connecting
        addLog(.info, "Connecting to \(url.absoluteString)...")

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        urlSession = URLSession(configuration: config)

        guard let session = urlSession else {
            connectionState = .error("Failed to create session")
            return
        }

        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()

        // Start receiving messages
        receiveTask = Task { [weak self] in
            await self?.receiveMessages()
        }

        // Send connect request
        do {
            let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
            let connectParams: [String: Any] = [
                "minProtocol": 3,
                "maxProtocol": 3,
                "client": [
                    "id": deviceId,
                    "mode": "terminal",
                    "name": "MoltTodo",
                    "version": "1.0.0",
                    "platform": "ios"
                ]
            ]

            let response = try await request(method: "connect", params: connectParams)
            if let json = try? JSONSerialization.jsonObject(with: response) as? [String: Any] {
                // Check for hello-ok or ok:true response
                let type = json["type"] as? String
                if type == "hello-ok" || (json["ok"] as? Bool == true) {
                    connectionState = .connected
                    addLog(.success, "Connected to gateway server")
                    startPingLoop()
                } else if let error = json["error"] as? [String: Any],
                          let message = error["message"] as? String {
                    connectionState = .error(message)
                    addLog(.error, "Connection failed: \(message)")
                } else {
                    connectionState = .error("Invalid handshake response")
                    addLog(.error, "Invalid handshake response")
                }
            } else {
                connectionState = .error("Invalid response format")
            }
        } catch {
            connectionState = .error(error.localizedDescription)
            addLog(.error, "Connection failed: \(error.localizedDescription)")
        }
    }

    func disconnect() {
        receiveTask?.cancel()
        pingTask?.cancel()
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        urlSession = nil
        connectionState = .disconnected
        addLog(.info, "Disconnected from gateway")
    }

    // MARK: - Commands

    func sendCommand(_ command: String) async {
        guard connectionState == .connected else {
            addLog(.error, "Not connected to gateway")
            return
        }

        isProcessingCommand = true
        currentCommand = command
        addLog(.info, "$ \(command)", source: "user")

        do {
            let params: [String: Any] = [
                "message": command,
                "stream": true
            ]

            // Use chat.send method for command execution
            let _ = try await request(method: "chat.send", params: params, timeout: 120)
            // Response will come via events
        } catch {
            addLog(.error, "Command failed: \(error.localizedDescription)")
            isProcessingCommand = false
            currentCommand = nil
        }
    }

    func abortCommand() async {
        guard isProcessingCommand else { return }

        do {
            let _ = try await request(method: "chat.abort", params: nil)
            addLog(.warning, "Command aborted")
        } catch {
            addLog(.error, "Failed to abort: \(error.localizedDescription)")
        }

        isProcessingCommand = false
        currentCommand = nil
    }

    // MARK: - Log Management

    func clearLogs() {
        logs.removeAll()
    }

    func addLog(_ level: LogEntry.LogLevel, _ message: String, source: String? = nil) {
        let entry = LogEntry(
            timestamp: Date(),
            level: level,
            message: message,
            source: source
        )
        logs.append(entry)

        // Keep last 500 logs
        if logs.count > 500 {
            logs.removeFirst(logs.count - 500)
        }
    }

    // MARK: - Private

    private func receiveMessages() async {
        while let ws = webSocket, !Task.isCancelled {
            do {
                let message = try await ws.receive()

                switch message {
                case .string(let text):
                    await handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        await handleMessage(text)
                    }
                @unknown default:
                    break
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        connectionState = .error("Connection lost")
                        addLog(.error, "Connection lost: \(error.localizedDescription)")
                    }
                }
                break
            }
        }
    }

    private func handleMessage(_ text: String) async {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            return
        }

        switch type {
        case "res":
            // Response to a request
            if let id = json["id"] as? String,
               let continuation = pendingRequests.removeValue(forKey: id) {
                if let ok = json["ok"] as? Bool, ok,
                   let payload = json["payload"] {
                    let payloadData = try? JSONSerialization.data(withJSONObject: payload)
                    continuation.resume(returning: payloadData ?? Data())
                } else if let error = json["error"] as? [String: Any],
                          let message = error["message"] as? String {
                    continuation.resume(throwing: GatewayError.serverError(message))
                } else {
                    continuation.resume(returning: Data())
                }
            }

        case "event":
            await handleEvent(json)

        default:
            break
        }
    }

    private func handleEvent(_ json: [String: Any]) async {
        guard let event = json["event"] as? String else { return }

        switch event {
        case "chat":
            // Chat response event
            if let payload = json["payload"] as? [String: Any] {
                await handleChatEvent(payload)
            }

        case "log":
            // Log event from server
            if let payload = json["payload"] as? [String: Any],
               let message = payload["message"] as? String {
                let levelStr = payload["level"] as? String ?? "info"
                let level = LogEntry.LogLevel(rawValue: levelStr.uppercased()) ?? .info
                let source = payload["source"] as? String
                addLog(level, message, source: source)
            }

        case "tick":
            // Heartbeat, ignore
            break

        default:
            // Log unknown events for debugging
            addLog(.debug, "Event: \(event)")
        }
    }

    private func handleChatEvent(_ payload: [String: Any]) async {
        let state = payload["state"] as? String ?? ""

        if let message = payload["message"] as? [String: Any],
           let content = message["content"] as? [[String: Any]] {
            for block in content {
                if let text = block["text"] as? String, !text.isEmpty {
                    // Stream text output
                    addLog(.info, text, source: "assistant")
                }
            }
        }

        if state == "final" || state == "error" {
            isProcessingCommand = false
            currentCommand = nil

            if state == "error" {
                if let error = payload["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    addLog(.error, message)
                }
            } else {
                addLog(.success, "Command completed")
            }
        }
    }

    private func request(method: String, params: [String: Any]?, timeout: TimeInterval = 30) async throws -> Data {
        guard let ws = webSocket else {
            throw GatewayError.notConnected
        }

        requestId += 1
        let id = "req-\(requestId)"

        var frame: [String: Any] = [
            "type": "req",
            "id": id,
            "method": method
        ]
        if let params = params {
            frame["params"] = params
        }

        let data = try JSONSerialization.data(withJSONObject: frame)
        let message = URLSessionWebSocketTask.Message.string(String(data: data, encoding: .utf8)!)

        return try await withCheckedThrowingContinuation { continuation in
            pendingRequests[id] = continuation

            Task {
                do {
                    try await ws.send(message)

                    // Setup timeout
                    try await Task.sleep(for: .seconds(timeout))
                    if let cont = pendingRequests.removeValue(forKey: id) {
                        cont.resume(throwing: GatewayError.timeout)
                    }
                } catch {
                    if let cont = pendingRequests.removeValue(forKey: id) {
                        cont.resume(throwing: error)
                    }
                }
            }
        }
    }

    private func startPingLoop() {
        pingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                guard let self = self, self.connectionState == .connected else { break }
                try? await self.webSocket?.sendPing { _ in }
            }
        }
    }
}

// MARK: - Errors

enum GatewayError: LocalizedError {
    case notConnected
    case timeout
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .notConnected: "Not connected to gateway"
        case .timeout: "Request timed out"
        case .serverError(let msg): msg
        }
    }
}
