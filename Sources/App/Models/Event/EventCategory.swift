import Fluent
import Vapor
final class EventCategory: Model, Content {
    static let schema = "eventCategories"
    
    @ID
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Siblings(through: EventCategoryPivot.self, from: \.$category, to: \.$event)
    var events: [Event]
    
    init() {}
    
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
