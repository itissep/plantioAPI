import Vapor

struct CreateCommentRequest: Content {
    var text: String
}

struct CommentDTO: Content {
    var id: UUID?
    var postID: UUID
    var authorUserID: UUID
    var text: String
    var createdAt: Date?

    init(from comment: Comment) {
        self.id = comment.id
        self.postID = comment.postID
        self.authorUserID = comment.authorUserID
        self.text = comment.text
        self.createdAt = comment.createdAt
    }
}
