import Fluent

struct AddIsGlobalToFeedPost: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("feed_posts")
            .field("is_global", .bool, .required, .sql(.default(false)))
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("feed_posts")
            .deleteField("is_global")
            .update()
    }
}
