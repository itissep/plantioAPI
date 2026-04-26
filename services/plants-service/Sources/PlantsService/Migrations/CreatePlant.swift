import Fluent

struct CreatePlant: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("plants")
            .id()
            .field("user_id", .uuid, .required)
            .field("name", .string, .required)
            .field("description", .string)
            .field("species", .string)
            .field("watering_period", .int)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("plants").delete()
    }
}
