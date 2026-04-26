import Fluent
import Vapor

enum NotificationsController {
    static func index(_ req: Request) async throws -> [NotificationDTO] {
        let userID = try req.requireUserID()
        let notifications = try await Notification.query(on: req.db)
            .filter(\.$userID == userID)
            .sort(\.$createdAt, .descending)
            .all()
        return notifications.map(NotificationDTO.init(from:))
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
