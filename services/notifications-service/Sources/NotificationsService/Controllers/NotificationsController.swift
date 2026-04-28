import Fluent
import Vapor

struct FollowNotificationRequest: Content {
    var followerID: UUID
    var followedUserID: UUID
    var followerName: String
}

enum NotificationsController {
    static func index(_ req: Request) async throws -> [NotificationDTO] {
        let userID = try req.requireUserID()
        let notifications = try await Notification.query(on: req.db)
            .filter(\.$userID == userID)
            .sort(\.$createdAt, .descending)
            .all()
        return notifications.map(NotificationDTO.init(from:))
    }

    static func notifyFollow(_ req: Request) async throws -> HTTPStatus {
        let body = try req.content.decode(FollowNotificationRequest.self)
        let notification = Notification(
            userID: body.followedUserID,
            title: "Новый подписчик",
            body: "\(body.followerName) подписался на вас"
        )
        try await notification.save(on: req.db)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(NotificationDTO(from: notification)),
           let str = String(data: data, encoding: .utf8) {
            await req.application.wsManager.send(str, to: body.followedUserID)
        }
        return .created
    }

    static func markRead(_ req: Request) async throws -> NotificationDTO {
        let userID = try req.requireUserID()
        guard let id = req.parameters.get("notificationID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid notification id")
        }
        guard let notification = try await Notification.find(id, on: req.db),
              notification.userID == userID else {
            throw Abort(.notFound)
        }
        notification.isRead = true
        try await notification.save(on: req.db)
        return NotificationDTO(from: notification)
    }
}
