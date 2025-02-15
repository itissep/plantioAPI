import Fluent

struct CreatePlant: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("plants")
            .id()
            .field("name", .string, .required)
            .field("desc", .string)
            .field("type", .string)
            .field("wateringPeriod", .int)
            .field("userID", .uuid, .required, .references("users", "id"))
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("plants").delete()
    }
}
