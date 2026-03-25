import Fluent
import Vapor

final class User: Model, Content, Authenticatable {
    static let schema = "users"

    @ID
    var id: UUID?

    @Field(key: "email")
    var email: String

    @Field(key: "password_hash")
    var passwordHash: String

    @Field(key: "name")
    var name: String

    @OptionalField(key: "avatar")
    var avatar: String?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}

    init(id: UUID? = nil, email: String, passwordHash: String, name: String, avatar: String? = nil) {
        self.id = id
        self.email = email
        self.passwordHash = passwordHash
        self.name = name
        self.avatar = avatar
    }

    struct Public: Content {
        var id: UUID?
        var email: String
        var name: String
        var avatar: String?

        init(from user: User) {
            self.id = user.id
            self.email = user.email
            self.name = user.name
            self.avatar = user.avatar
        }
    }

    /// Публичный профиль без email
    struct PublicProfile: Content {
        var id: UUID?
        var name: String
        var avatar: String?

        init(from user: User) {
            self.id = user.id
            self.name = user.name
            self.avatar = user.avatar
        }
    }
}
