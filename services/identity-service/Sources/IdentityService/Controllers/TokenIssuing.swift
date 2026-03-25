import Fluent
import JWT
import Vapor

extension Request {
    func accessTokenTTL() -> TimeInterval {
        let s = Environment.get("JWT_ACCESS_EXPIRES") ?? "900"
        return TimeInterval(Int(s) ?? 900)
    }

    func refreshTokenTTL() -> TimeInterval {
        let s = Environment.get("JWT_REFRESH_EXPIRES") ?? "604800"
        return TimeInterval(Int(s) ?? 604_800)
    }

    func issueTokens(for user: User) async throws -> AuthTokensResponse {
        let userId = try user.requireID()
        let accessPayload = AccessTokenPayload(
            subject: SubjectClaim(value: userId.uuidString),
            email: user.email,
            typ: "access",
            exp: ExpirationClaim(value: Date().addingTimeInterval(accessTokenTTL()))
        )
        let accessToken = try jwt.sign(accessPayload)
        let rawRefresh = TokenHasher.randomRawToken()
        let tokenHash = TokenHasher.hash(rawRefresh)
        let refresh = RefreshToken(
            tokenHash: tokenHash,
            userID: userId,
            expiresAt: Date().addingTimeInterval(refreshTokenTTL())
        )
        try await refresh.save(on: db)
        return AuthTokensResponse(
            accessToken: accessToken,
            refreshToken: rawRefresh,
            user: User.Public(from: user)
        )
    }
}
