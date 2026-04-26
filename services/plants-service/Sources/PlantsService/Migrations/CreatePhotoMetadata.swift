import Fluent

struct CreatePhotoMetadata: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("photo_metadata")
            .id()
            .field("plant_id", .uuid, .required, .references("plants", .id, onDelete: .cascade))
            .field("user_id", .uuid, .required)
            .field("relative_path", .string, .required)
            .field("mime_type", .string, .required)
            .field("byte_size", .int, .required)
            .field("created_at", .datetime)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("photo_metadata").delete()
    }
}
