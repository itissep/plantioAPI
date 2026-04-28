import Fluent
import Vapor

final class Notification: Model, Content {
    static let schema = "notifications"

    @ID
    var id: UUID?

    @Field(key: "user_id")
    var userID: UUID

    @Field(key: "title")
    var title: String

    @Field(key: "body")
    var body: String

    @Field(key: "is_read")
    var isRead: Bool

    @OptionalField(key: "care_event_id")
    var careEventID: UUID?

    @OptionalField(key: "plant_id")
    var plantID: UUID?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        userID: UUID,
        title: String,
        body: String,
        careEventID: UUID? = nil,
        plantID: UUID? = nil
    ) {
        self.id = id
        self.userID = userID
        self.title = title
        self.body = body
        self.isRead = false
        self.careEventID = careEventID
        self.plantID = plantID
    }
}
