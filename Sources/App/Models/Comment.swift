import Vapor
import Fluent

final class Comment: Model, Content {

    static let schema = "comments"

    @ID
    var id: UUID?

    @Field(key: "text")
    var text: String
    
    //MARK:  RELATIONS
    
    @Parent(key: "userID")
    var user: User
    
    @Parent(key: "postID")
    var post: Post
    
    //MARK:  Timestamps
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() {}
    
    init(
        id: UUID? = nil,
        text: String,
        userID: User.IDValue,
        postID: Post.IDValue
    ) {
        self.id = id
        
        self.text = text
        
        self.$post.id = postID
        self.$user.id = userID
    }
}
