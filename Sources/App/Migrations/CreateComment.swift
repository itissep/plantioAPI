import Fluent

struct CreateComment: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("comments")
            .id()
            .field("text", .string, .required)
        
            .field("userID", .uuid, .required, .references("users", "id"))
            .field("postID", .uuid, .required, .references("posts", "id"))
        
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("comments").delete()
    }
}
