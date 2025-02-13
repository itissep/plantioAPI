import Fluent

struct CreatePlant: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("plants")
            .id()
            .field("name", .string, .required)
            .field("desc", .string, .required)
            .field("userID", .uuid, .required, .references("users", "id"))
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("plants").delete()
    }
}
