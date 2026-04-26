import Vapor

func routes(_ app: Application) throws {
    app.get("health") { _ in
        "OK"
    }

    let auth = JWTUserAuthenticator()
    let protected = app.grouped(auth).grouped(AuthenticatedUser.guardMiddleware())

    protected.get("posts", use: FeedController.index)

    app.get("posts", "global", use: FeedController.global)
}
