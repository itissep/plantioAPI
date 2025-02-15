import Fluent

struct CreateEventCategoryPivot: Migration {

    func prepare(on database: Database) -> EventLoopFuture<Void> {

        database.schema("event-category-pivot")
            .id()
            .field("eventID", .uuid, .required,
                   .references("events", "id", onDelete: .cascade))
            .field("categoryID", .uuid, .required,
                   .references("eventCategories", "id", onDelete: .cascade))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("event-category-pivot").delete()
    }
}
