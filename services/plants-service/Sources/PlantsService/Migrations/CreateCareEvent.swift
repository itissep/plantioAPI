import Fluent

struct CreateCareEvent: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("care_events")
            .id()
            .field("plant_id", .uuid, .required, .references("plants", .id, onDelete: .cascade))
            .field("user_id", .uuid, .required)
            .field("kind", .string, .required)
            .field("notes", .string)
            .field("occurred_at", .datetime, .required)
            .field("created_at", .datetime)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("care_events").delete()
    }
}
