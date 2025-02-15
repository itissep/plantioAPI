import Fluent
import Foundation

final class EventCategoryPivot: Model {
    static let schema = "event-category-pivot"
    
    @ID
    var id: UUID?
    
    @Parent(key: "eventID")
    var event: Event
    
    @Parent(key: "categoryID")
    var category: EventCategory
    
    init() {}
    
    init(
        id: UUID? = nil,
        event: Event,
        category: EventCategory
    ) throws {
        self.id = id
        self.$event.id = try event.requireID()
        self.$category.id = try category.requireID()
    }
}
