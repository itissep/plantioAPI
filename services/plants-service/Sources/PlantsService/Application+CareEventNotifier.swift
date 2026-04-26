import Vapor

private struct CareEventNotifierKey: StorageKey {
    typealias Value = CareEventNotifier
}

extension Application {
    var careEventNotifier: CareEventNotifier {
        get {
            guard let v = storage[CareEventNotifierKey.self] else {
                fatalError("careEventNotifier not configured")
            }
            return v
        }
        set { storage[CareEventNotifierKey.self] = newValue }
    }
}

extension Request {
    var careEventNotifier: CareEventNotifier {
        application.careEventNotifier
    }
}
