import Vapor

struct NotificationDTO: Content {
    var id: UUID?
    var title: String
    var body: String
    var isRead: Bool
    var careEventID: UUID?
    var plantID: UUID?
    var createdAt: Date?

    init(from n: Notification) {
        self.id = n.id
        self.title = n.title
        self.body = n.body
        self.isRead = n.isRead
        self.careEventID = n.careEventID
        self.plantID = n.plantID
        self.createdAt = n.createdAt
    }
}
