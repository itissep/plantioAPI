import Vapor

struct RegisterRequest: Content {
    var email: String
    var password: String
    var name: String
    var avatar: String?
}

struct LoginRequest: Content {
    var email: String
    var password: String
}

struct RefreshRequest: Content {
    var refreshToken: String
}

struct LogoutRequest: Content {
    var refreshToken: String
}

struct AuthTokensResponse: Content {
    var accessToken: String
    var refreshToken: String
    var user: User.Public
}

struct UpdateProfileRequest: Content {
    var name: String?
    var avatar: String?
}

struct MessageResponse: Content {
    var message: String
}
