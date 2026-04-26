import Vapor

private struct CommentPublisherKey: StorageKey {
    typealias Value = CommentPublisher
}

extension Application {
    var commentPublisher: CommentPublisher {
        get {
            guard let v = storage[CommentPublisherKey.self] else {
                fatalError("CommentPublisher not configured")
            }
            return v
        }
        set { storage[CommentPublisherKey.self] = newValue }
    }
}
