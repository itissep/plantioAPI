import Fluent

struct CreateFeedPost: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("feed_posts")
            .id()
            .field("owner_user_id", .uuid, .required)
            .field("author_user_id", .uuid, .required)
            .field("plant_id", .uuid, .required)
            .field("care_event_id", .uuid, .required)
            .field("kind", .string, .required)
            .field("occurred_at", .datetime, .required)
            .field("created_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("feed_posts").delete()
    }
}
