import Fluent

struct CreateRefreshToken: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("refresh_tokens")
            .id()
            .field("token_hash", .string, .required)
            .field("user_id", .uuid, .required, .references("users", .id, onDelete: .cascade))
            .field("expires_at", .datetime, .required)
            .unique(on: "token_hash")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("refresh_tokens").delete()
    }
}
