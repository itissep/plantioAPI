import Fluent

fileprivate enum BasicEventCategories {
    static let repotting = EventCategory(name: "repotting")
    static let adopting = EventCategory(name: "adopting")
    static let watering = EventCategory(name: "watering")
    static let fertilizing = EventCategory(name: "fertilizing")
}

struct CreateEventCategory: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("eventCategories")
            .id()
            .field("name", .string, .required)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("eventCategories").delete()
    }
}
