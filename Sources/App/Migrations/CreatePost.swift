import Fluent

struct CreatePost: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("posts")
            .id()
            .field("title", .string, .required)
            .field("text", .string, .required)
        
            .field("likesUserIDs", .array(of: .string), .required)
            .field("imagesURLs", .array(of: .string), .required)
        
            .field("userID", .uuid, .required, .references("users", "id"))
            .field("plantID", .uuid, .references("plants", "id"))
        
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("posts").delete()
    }
}

