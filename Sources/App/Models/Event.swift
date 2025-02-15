import Vapor
import Fluent

final class Event: Model, Content {

    static let schema = "events"

    @ID
    var id: UUID?

    @OptionalField(key: "notes")
    var notes: String?
    
    @Parent(key: "plantID")
    var plant: Plant
    
    //MARK:  Timestamps
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() {}
    
    init(
        id: UUID? = nil,
        notes: String?,
        plantID: Plant.IDValue
//        type: String?
    ) {
        self.id = id
        self.notes = notes
//        self.type = type
        self.$plant.id = plantID
    }
}
