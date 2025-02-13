import Vapor
import Fluent

final class Plant: Model, Content {

    static let schema = "plants"

    @ID
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "desc")
    var desc: String
    
    @Parent(key: "userID")
    var user: User
    
    init() {}
    
    init(id: UUID? = nil, name: String, desc: String, userID: User.IDValue) {
        self.id = id
        self.name = name
        self.desc = desc
        self.$user.id = userID
    }
}
