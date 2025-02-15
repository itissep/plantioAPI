import Vapor
import Fluent

final class Plant: Model, Content {

    static let schema = "plants"

    @ID
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @OptionalField(key: "desc")
    var desc: String?

    @OptionalField(key: "type")
    var type: String?
    
    @OptionalField(key: "wateringPeriod")
    var wateringPeriod: Int?
    
    @Parent(key: "userID")
    var user: User
    
    @Children(for: \.$plant)
    var events: [Event]

    @Children(for: \.$plant)
    var posts: [Post]
    
    //MARK:  Timestamps
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() {}
    
    init(
        id: UUID? = nil,
        name: String,
        desc: String?,
        userID: User.IDValue,
        wateringPeriod: Int?,
        type: String?
    ) {
        self.id = id
        self.name = name
        self.desc = desc
        self.type = type
        self.$user.id = userID
        self.wateringPeriod = wateringPeriod
    }
}

// TODO: add plant category
