import Vapor

func routes(_ app: Application) throws {
    app.get("health") { _ in
        "OK"
    }

    let auth = JWTUserAuthenticator()
    let protected = app.grouped(auth).grouped(AuthenticatedUser.guardMiddleware())

    protected.get("posts", use: FeedController.index)
    protected.post("posts", ":postID", "comments", use: CommentController.create)
    protected.delete("posts", ":postID", "comments", ":commentID", use: CommentController.delete)

    app.get("posts", "global", use: FeedController.global)
    app.get("posts", ":postID", "comments", use: CommentController.index)
}
