import Vapor

struct UserBearerAuthenticator: AsyncBearerAuthenticator {
    func authenticate(bearer: BearerAuthorization, for request: Request) async throws {
        let payload = try request.jwt.verify(bearer.token, as: AccessTokenPayload.self)
        guard let id = UUID(uuidString: payload.subject.value) else { return }
        guard let user = try await User.find(id, on: request.db) else { return }
        request.auth.login(user)
    }
}
