import Fluent
import Vapor

final class Plant: Model, Content {
    static let schema = "plants"

    @ID
    var id: UUID?

    @Field(key: "user_id")
    var userID: UUID

    @Field(key: "name")
    var name: String

    @OptionalField(key: "description")
    var description: String?

    @OptionalField(key: "species")
    var species: String?

    @OptionalField(key: "watering_period")
    var wateringPeriod: Int?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    @Children(for: \.$plant)
    var careEvents: [CareEvent]

    @Children(for: \.$plant)
    var photos: [PhotoMetadata]

    init() {}

    init(
        id: UUID? = nil,
        userID: UUID,
        name: String,
        description: String? = nil,
        species: String? = nil,
        wateringPeriod: Int? = nil
    ) {
        self.id = id
        self.userID = userID
        self.name = name
        self.description = description
        self.species = species
        self.wateringPeriod = wateringPeriod
    }
}
