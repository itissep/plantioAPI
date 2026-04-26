import Vapor

func routes(_ app: Application) throws {
    app.get("health") { _ in "OK" }
    try registerOpenAPIRoutes(app)

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
    users.get(":userID", "followers", use: UserController.followerProfiles)
    users.get(":userID", "following", use: UserController.followingProfiles)

    let internal_ = app.grouped("internal")
    internal_.get("users", ":userID", "followers", use: UserController.followers)
}
