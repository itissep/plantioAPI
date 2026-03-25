import Fluent

struct CreateFollow: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("follows")
            .id()
            .field("follower_id", .uuid, .required, .references("users", .id, onDelete: .cascade))
            .field("following_id", .uuid, .required, .references("users", .id, onDelete: .cascade))
            .field("created_at", .datetime)
            .unique(on: "follower_id", "following_id")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("follows").delete()
    }
}
