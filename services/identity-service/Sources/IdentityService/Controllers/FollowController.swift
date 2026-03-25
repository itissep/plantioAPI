import Fluent
import Vapor

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
