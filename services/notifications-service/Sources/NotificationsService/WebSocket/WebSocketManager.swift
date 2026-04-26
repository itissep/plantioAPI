import Vapor

actor WebSocketManager {
    private var connections: [UUID: [WebSocket]] = [:]

    func add(_ ws: WebSocket, for userID: UUID) {
        connections[userID, default: []].append(ws)
    }

    func remove(_ ws: WebSocket, for userID: UUID) {
        connections[userID]?.removeAll { $0 === ws }
        if connections[userID]?.isEmpty == true {
            connections.removeValue(forKey: userID)
        }
    }

    func send(_ message: String, to userID: UUID) async {
        guard let sockets = connections[userID] else { return }
        for ws in sockets where !ws.isClosed {
            try? await ws.send(message)
        }
    }
}
