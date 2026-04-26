import Fluent

struct CreateNotification: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("notifications")
            .id()
            .field("user_id", .uuid, .required)
            .field("title", .string, .required)
            .field("body", .string, .required)
            .field("is_read", .bool, .required)
            .field("care_event_id", .uuid, .required)
            .field("plant_id", .uuid, .required)
            .field("created_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("notifications").delete()
    }
}
