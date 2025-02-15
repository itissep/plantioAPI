import Fluent

struct CreateEvent: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("events")
            .id()
            .field("notes", .string)
//            .field("type", .string)
            .field("plantID", .uuid, .required, .references("plants", "id"))
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("events").delete()
    }
}
