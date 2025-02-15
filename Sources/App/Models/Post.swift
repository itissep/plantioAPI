import Vapor
import Fluent

final class Post: Model, Content {

    static let schema = "posts"

    @ID
    var id: UUID?
    
    @Field(key: "title")
    var title: String
    
    @Field(key: "text")
    var text: String
    
    @Field(key: "likesUserIDs")
    var likesUsers: [String]
    
    @Field(key: "imagesURLs")
    var imagesURLs: [String]
    
    @Parent(key: "userID")
    var user: User
    
    @OptionalParent(key: "plantID")
    var plant: Plant?
    
    // TODO: add comments
//    @Children(for: \.$plant)
//    var events: [Event]
    
    //MARK:  Timestamps
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() {}
    
    init(
        id: UUID? = nil,
        title: String,
        text: String,
        userID: User.IDValue,
        plantID: Plant.IDValue?,
        likesUsers: [String],
        imagesURLs: [String]
    ) {
        self.id = id
        self.title = title
        self.text = text
        
        self.$user.id = userID
        self.$plant.id = plantID
        
        self.likesUsers = likesUsers
        self.imagesURLs = imagesURLs
    }
}
