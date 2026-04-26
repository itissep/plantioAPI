import Fluent
import Vapor

final class CareEvent: Model, Content {
    static let schema = "care_events"

    @ID
    var id: UUID?

    @Parent(key: "plant_id")
    var plant: Plant

    @Field(key: "user_id")
    var userID: UUID

    @Field(key: "kind")
    var kind: String

    @OptionalField(key: "notes")
    var notes: String?

    @Field(key: "occurred_at")
    var occurredAt: Date

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        plantID: Plant.IDValue,
        userID: UUID,
        kind: String,
        notes: String? = nil,
        occurredAt: Date
    ) {
        self.id = id
        self.$plant.id = plantID
        self.userID = userID
        self.kind = kind
        self.notes = notes
        self.occurredAt = occurredAt
    }
}
