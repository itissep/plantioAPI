import Fluent
import Vapor

enum UserController {
    static func me(_ req: Request) async throws -> User.Public {
        let user = try req.auth.require(User.self)
        return User.Public(from: user)
    }

    static func updateMe(_ req: Request) async throws -> User.Public {
        let user = try req.auth.require(User.self)
        let body = try req.content.decode(UpdateProfileRequest.self)
        if let name = body.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            user.name = name
        }
        if let avatar = body.avatar {
            let t = avatar.trimmingCharacters(in: .whitespacesAndNewlines)
            user.avatar = t.isEmpty ? nil : t
        }
        try await user.save(on: req.db)
        return User.Public(from: user)
    }

    static func publicProfile(_ req: Request) async throws -> User.PublicProfile {
        guard let id = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid user id")
        }
        guard let user = try await User.find(id, on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }
        return User.PublicProfile(from: user)
    }

    static func followers(_ req: Request) async throws -> FollowerIDsResponse {
        guard let id = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid user id")
        }
        let follows = try await Follow.query(on: req.db)
            .filter(\.$followingID == id)
            .all()
        return FollowerIDsResponse(followerIDs: follows.map { $0.followerID })
    }

    static func followerProfiles(_ req: Request) async throws -> [User.PublicProfile] {
        guard let id = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid user id")
        }
        let follows = try await Follow.query(on: req.db)
            .filter(\.$followingID == id)
            .all()
        let ids = follows.map { $0.followerID }
        guard !ids.isEmpty else { return [] }
        let users = try await User.query(on: req.db).filter(\.$id ~~ ids).all()
        return users.map(User.PublicProfile.init(from:))
    }

    static func followingProfiles(_ req: Request) async throws -> [User.PublicProfile] {
        guard let id = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid user id")
        }
        let follows = try await Follow.query(on: req.db)
            .filter(\.$followerID == id)
            .all()
        let ids = follows.map { $0.followingID }
        guard !ids.isEmpty else { return [] }
        let users = try await User.query(on: req.db).filter(\.$id ~~ ids).all()
        return users.map(User.PublicProfile.init(from:))
    }
}

struct FollowerIDsResponse: Content {
    var followerIDs: [UUID]
}
