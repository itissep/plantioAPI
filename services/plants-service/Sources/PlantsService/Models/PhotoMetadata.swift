import Fluent
import Vapor

final class PhotoMetadata: Model, Content {
    static let schema = "photo_metadata"

    @ID
    var id: UUID?

    @Parent(key: "plant_id")
    var plant: Plant

    @Field(key: "user_id")
    var userID: UUID

    /// Относительный путь под MEDIA_PATH, напр. "<plantUUID>/<fileUUID>.jpg"
    @Field(key: "relative_path")
    var relativePath: String

    @Field(key: "mime_type")
    var mimeType: String

    @Field(key: "byte_size")
    var byteSize: Int

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        plantID: Plant.IDValue,
        userID: UUID,
        relativePath: String,
        mimeType: String,
        byteSize: Int
    ) {
        self.id = id
        self.$plant.id = plantID
        self.userID = userID
        self.relativePath = relativePath
        self.mimeType = mimeType
        self.byteSize = byteSize
    }
}
