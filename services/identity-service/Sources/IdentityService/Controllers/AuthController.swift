import Fluent
import Vapor

enum AuthController {
    static func register(_ req: Request) async throws -> AuthTokensResponse {
        let body = try req.content.decode(RegisterRequest.self)
        let email = body.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard email.contains("@"), email.count >= 3 else {
            throw Abort(.badRequest, reason: "Invalid email")
        }
        guard body.password.count >= 8 else {
            throw Abort(.badRequest, reason: "Password must be at least 8 characters")
        }
        guard !body.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw Abort(.badRequest, reason: "Name is required")
        }
        if try await User.query(on: req.db).filter(\.$email == email).first() != nil {
            throw Abort(.conflict, reason: "Email already registered")
        }
        let hash = try Bcrypt.hash(body.password)
        let user = User(
            email: email,
            passwordHash: hash,
            name: body.name.trimmingCharacters(in: .whitespacesAndNewlines),
            avatar: body.avatar?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        )
        try await user.save(on: req.db)
        return try await req.issueTokens(for: user)
    }

    static func login(_ req: Request) async throws -> AuthTokensResponse {
        let body = try req.content.decode(LoginRequest.self)
        let email = body.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard let user = try await User.query(on: req.db).filter(\.$email == email).first() else {
            throw Abort(.unauthorized, reason: "Invalid credentials")
        }
        guard (try? Bcrypt.verify(body.password, created: user.passwordHash)) == true else {
            throw Abort(.unauthorized, reason: "Invalid credentials")
        }
        return try await req.issueTokens(for: user)
    }

    static func refresh(_ req: Request) async throws -> AuthTokensResponse {
        let body = try req.content.decode(RefreshRequest.self)
        let tokenHash = TokenHasher.hash(body.refreshToken)
        guard let record = try await RefreshToken.query(on: req.db).filter(\.$tokenHash == tokenHash).first() else {
            throw Abort(.unauthorized, reason: "Invalid refresh token")
        }
        if record.expiresAt < Date() {
            try await record.delete(on: req.db)
            throw Abort(.unauthorized, reason: "Refresh token expired")
        }
        guard let user = try await User.find(record.userID, on: req.db) else {
            try await record.delete(on: req.db)
            throw Abort(.unauthorized, reason: "Invalid refresh token")
        }
        try await record.delete(on: req.db)
        return try await req.issueTokens(for: user)
    }

    static func logout(_ req: Request) async throws -> MessageResponse {
        let body = try req.content.decode(LogoutRequest.self)
        let tokenHash = TokenHasher.hash(body.refreshToken)
        try await RefreshToken.query(on: req.db).filter(\.$tokenHash == tokenHash).delete()
        return MessageResponse(message: "Logged out")
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
