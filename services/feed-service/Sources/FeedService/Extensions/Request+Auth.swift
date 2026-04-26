import Vapor

extension Request {
    func requireUserID() throws -> UUID {
        try auth.require(AuthenticatedUser.self).id
    }
}
