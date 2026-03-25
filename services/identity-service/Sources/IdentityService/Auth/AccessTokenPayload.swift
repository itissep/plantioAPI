import JWT
import Vapor

struct AccessTokenPayload: JWTPayload {
    var subject: SubjectClaim
    var email: String
    var typ: String
    var exp: ExpirationClaim

    func verify(using signer: JWTSigner) throws {
        try exp.verifyNotExpired()
        guard typ == "access" else {
            throw JWTError.claimVerificationFailure(name: "typ", reason: "expected access")
        }
    }
}
