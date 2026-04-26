import Vapor

struct FeedPostDTO: Content {
    var id: UUID?
    var authorUserID: UUID
    var plantID: UUID
    var careEventID: UUID
    var kind: String
    var occurredAt: Date
    var createdAt: Date?

    init(from post: FeedPost) {
        self.id = post.id
        self.authorUserID = post.authorUserID
        self.plantID = post.plantID
        self.careEventID = post.careEventID
        self.kind = post.kind
        self.occurredAt = post.occurredAt
        self.createdAt = post.createdAt
    }
}
