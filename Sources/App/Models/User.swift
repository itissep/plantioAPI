import Fluent
import Vapor

final class User: Model, Content {
    static let schema = "users"
    
    @ID
    var id: UUID?
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "password")
    var password: String
    
    //MARK: USER INFO
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "email")
    var email: String
    
    @OptionalField(key: "bio")
    var bio: String?
    
    @OptionalField(key: "avatarURL")
    var avatarURL: String?
    
    //MARK: RELATIONS
    
    @Children(for: \.$user)
    var plants: [Plant]
    
    // add posts
    // add comments
    // add notifications
    // add subscriptions
    
    //MARK:  Timestamps
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() {}
    
    init(
        id: UUID? = nil,
        username: String,
        password: String,
        name: String,
        email: String,
        bio: String?,
        avatarURL: String?
    ) {
        self.name = name
        self.username = username
        self.password = password
        self.name = name
        self.email = email
        self.bio = bio
        self.avatarURL = avatarURL
    }
    
    final class Public: Content {
        var id: UUID?
        var name: String
        var username: String
        var bio: String?
        var avatarURL: String?
        
        init(
            id: UUID?,
            name: String,
            username: String,
            bio: String?,
            avatarURL: String?
        ) {
            self.id = id
            self.name = name
            self.username = username
            self.bio = bio
            self.avatarURL = avatarURL
        }
    }
}

extension User {
    func convertToPublic() -> User.Public {
        User.Public(
            id: id,
            name: name,
            username: username,
            bio: bio,
            avatarURL: avatarURL
        )
    }
}


extension EventLoopFuture where Value: User {

    func convertToPublic() -> EventLoopFuture<User.Public> {
        self.map { user in
            return user.convertToPublic()
        }
    }
}

extension Collection where Element: User {
    func convertToPublic() -> [User.Public] {
        self.map { $0.convertToPublic() }
    }
}

extension EventLoopFuture where Value == Array<User> {
    func convertToPublic() -> EventLoopFuture<[User.Public]> {
        self.map { $0.convertToPublic() }
    }
}

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$username
    static let passwordHashKey = \User.$password

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}
