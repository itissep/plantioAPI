import Vapor

struct AuthenticatedUser: Authenticatable {
    var id: UUID
}
