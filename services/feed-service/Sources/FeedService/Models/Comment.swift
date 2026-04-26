import Fluent
import Vapor

final class Comment: Model, Content {
    static let schema = "comments"

    @ID
    var id: UUID?

    @Field(key: "post_id")
    var postID: UUID

    @Field(key: "author_user_id")
    var authorUserID: UUID

    @Field(key: "text")
    var text: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    init(id: UUID? = nil, postID: UUID, authorUserID: UUID, text: String) {
        self.id = id
        self.postID = postID
        self.authorUserID = authorUserID
        self.text = text
    }
}
