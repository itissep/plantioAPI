import Vapor

func routes(_ app: Application) throws {
    app.get("health") { _ in
        "OK"
    }

    let auth = JWTUserAuthenticator()
    let protected = app.grouped(auth).grouped(AuthenticatedUser.guardMiddleware())

    protected.get("notifications", use: NotificationsController.index)
    protected.post("notifications", ":notificationID", "read", use: NotificationsController.markRead)
}
