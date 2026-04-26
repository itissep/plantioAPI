import JWT
import Vapor

struct JWTUserAuthenticator: AsyncBearerAuthenticator {
    func authenticate(bearer: BearerAuthorization, for request: Request) async throws {
        let payload = try request.jwt.verify(bearer.token, as: AccessTokenPayload.self)
        guard let id = UUID(uuidString: payload.subject.value) else { return }
        request.auth.login(AuthenticatedUser(id: id))
    }
}
