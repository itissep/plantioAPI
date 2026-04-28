import Vapor

func routes(_ app: Application) throws {
    app.get("health") { _ in "OK" }
    try registerOpenAPIRoutes(app)

    let auth = JWTUserAuthenticator()
    let protected = app.grouped(auth).grouped(AuthenticatedUser.guardMiddleware())

    protected.get("notifications", use: NotificationsController.index)
    protected.post("notifications", ":notificationID", "read", use: NotificationsController.markRead)

    // Internal endpoint — called by other services, no auth required
    app.grouped("internal").post("notify", "follow", use: NotificationsController.notifyFollow)

    app.webSocket("ws") { req, ws in
        guard let token = req.query[String.self, at: "token"],
              let payload = try? req.jwt.verify(token, as: AccessTokenPayload.self),
              let userID = UUID(uuidString: payload.subject.value) else {
            _ = ws.close(code: .policyViolation)
            return
        }

        let manager = req.application.wsManager
        Task {
            await manager.add(ws, for: userID)
            req.application.logger.info("WebSocket: user \(userID) connected")

            ws.onClose.whenComplete { _ in
                Task {
                    await manager.remove(ws, for: userID)
                    req.application.logger.info("WebSocket: user \(userID) disconnected")
                }
            }
        }
    }
}
