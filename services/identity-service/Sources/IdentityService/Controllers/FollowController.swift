import Fluent
import Vapor

private struct FollowNotificationPayload: Encodable {
    let followerID: UUID
    let followedUserID: UUID
    let followerName: String
}

enum FollowController {
    static func follow(_ req: Request) async throws -> Response {
        let current = try req.auth.require(User.self)
        guard let targetID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid user id")
        }
        let selfID = try current.requireID()
        guard targetID != selfID else {
            throw Abort(.badRequest, reason: "Cannot follow yourself")
        }
        guard try await User.find(targetID, on: req.db) != nil else {
            throw Abort(.notFound, reason: "User not found")
        }
        let exists = try await Follow.query(on: req.db)
            .filter(\.$followerID == selfID)
            .filter(\.$followingID == targetID)
            .first() != nil
        if exists {
            return Response(status: .ok)
        }
        let follow = Follow(followerID: selfID, followingID: targetID)
        try await follow.save(on: req.db)

        // Fire-and-forget follow notification
        let appClient = req.application.client
        let payload = FollowNotificationPayload(
            followerID: selfID,
            followedUserID: targetID,
            followerName: current.name
        )
        if let data = try? JSONEncoder().encode(payload) {
            Task {
                let url = Environment.get("NOTIFICATIONS_SERVICE_URL") ?? "http://notifications-service:3004"
                let uri = URI(string: "\(url)/internal/notify/follow")
                var headers = HTTPHeaders()
                headers.replaceOrAdd(name: .contentType, value: "application/json")
                var clientReq = ClientRequest(method: .POST, url: uri, headers: headers)
                clientReq.body = ByteBuffer(data: data)
                _ = try? await appClient.send(clientReq)
            }
        }

        return Response(status: .created)
    }

    static func unfollow(_ req: Request) async throws -> Response {
        let current = try req.auth.require(User.self)
        guard let targetID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid user id")
        }
        let selfID = try current.requireID()
        try await Follow.query(on: req.db)
            .filter(\.$followerID == selfID)
            .filter(\.$followingID == targetID)
            .delete()
        return Response(status: .noContent)
    }
}
