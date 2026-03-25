import Fluent
import Vapor

final class RefreshToken: Model {
    static let schema = "refresh_tokens"

    @ID
    var id: UUID?

    @Field(key: "token_hash")
    var tokenHash: String

    @Field(key: "user_id")
    var userID: UUID

    @Field(key: "expires_at")
    var expiresAt: Date

    init() {}

    init(id: UUID? = nil, tokenHash: String, userID: UUID, expiresAt: Date) {
        self.id = id
        self.tokenHash = tokenHash
        self.userID = userID
        self.expiresAt = expiresAt
    }
}
