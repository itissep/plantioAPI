import Fluent
import Vapor

final class FeedPost: Model, Content {
    static let schema = "feed_posts"

    @ID
    var id: UUID?

    @Field(key: "owner_user_id")
    var ownerUserID: UUID

    @Field(key: "author_user_id")
    var authorUserID: UUID

    @Field(key: "plant_id")
    var plantID: UUID

    @Field(key: "care_event_id")
    var careEventID: UUID

    @Field(key: "kind")
    var kind: String

    @Field(key: "occurred_at")
    var occurredAt: Date

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        ownerUserID: UUID,
        authorUserID: UUID,
        plantID: UUID,
        careEventID: UUID,
        kind: String,
        occurredAt: Date
    ) {
        self.id = id
        self.ownerUserID = ownerUserID
        self.authorUserID = authorUserID
        self.plantID = plantID
        self.careEventID = careEventID
        self.kind = kind
        self.occurredAt = occurredAt
    }
}
