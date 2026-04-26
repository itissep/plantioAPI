import Vapor

private struct WebSocketManagerKey: StorageKey {
    typealias Value = WebSocketManager
}

extension Application {
    var wsManager: WebSocketManager {
        get {
            guard let v = storage[WebSocketManagerKey.self] else {
                fatalError("WebSocketManager not configured")
            }
            return v
        }
        set { storage[WebSocketManagerKey.self] = newValue }
    }
}
