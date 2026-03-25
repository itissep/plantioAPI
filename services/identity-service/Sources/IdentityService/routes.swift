import Vapor

func routes(_ app: Application) throws {
    app.get("health") { _ in
        "OK"
    }

    let auth = app.grouped("auth")
    auth.post("register", use: AuthController.register)
    auth.post("login", use: AuthController.login)
    auth.post("refresh", use: AuthController.refresh)
    auth.post("logout", use: AuthController.logout)

    let users = app.grouped("users")
    let bearer = UserBearerAuthenticator()
    let protected = users.grouped(bearer).grouped(User.guardMiddleware())

    protected.get("me", use: UserController.me)
    protected.put("me", use: UserController.updateMe)
    protected.post(":userID", "follow", use: FollowController.follow)
    protected.delete(":userID", "follow", use: FollowController.unfollow)

    users.get(":userID", use: UserController.publicProfile)
}
