import Testing
import VaporTesting
@testable import IdentityService

@Suite("Identity Service")
struct IdentityServiceTests {

    private func withApp(_ test: (Application) async throws -> ()) async throws {
        let app = try await Application.make(.testing)
        do {
            try configure(app)
            try await test(app)
        } catch {
            try await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }

    @Test("GET /health returns OK")
    func health() async throws {
        try await withApp { app in
            try await app.testing().test(.GET, "health", afterResponse: { res async in
                #expect(res.status == .ok)
                #expect(res.body.string == "OK")
            })
        }
    }

    @Test("TokenHasher is deterministic")
    func tokenHasherStable() {
        let a = TokenHasher.hash("same-secret")
        let b = TokenHasher.hash("same-secret")
        #expect(a == b)
        #expect(a != TokenHasher.hash("other"))
    }

    @Test("Register, login, /me, profile, follow, refresh, logout")
    func authAndUsersFlow() async throws {
        try await withApp { app in
            let reg = RegisterRequest(email: "u1@example.com", password: "password12", name: "User One", avatar: nil)
            var accessToken = ""
            var refreshToken = ""
            var userId: UUID?
            var user2Id: UUID?

            try await app.testing().test(.POST, "auth/register", beforeRequest: { req in
                try req.content.encode(reg)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let body = try res.content.decode(AuthTokensResponse.self)
                accessToken = body.accessToken
                refreshToken = body.refreshToken
                userId = body.user.id
                #expect(body.user.email == "u1@example.com")
            })

            try await app.testing().test(.POST, "auth/register", beforeRequest: { req in
                try req.content.encode(reg)
            }, afterResponse: { res async throws in
                #expect(res.status == .conflict)
            })

            try await app.testing().test(
                .GET,
                "users/me",
                headers: ["Authorization": "Bearer \(accessToken)"],
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let me = try res.content.decode(User.Public.self)
                    #expect(me.email == "u1@example.com")
                }
            )

            try await app.testing().test(
                .PUT,
                "users/me",
                headers: ["Authorization": "Bearer \(accessToken)"],
                beforeRequest: { req in
                    try req.content.encode(UpdateProfileRequest(name: "Updated", avatar: nil))
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let me = try res.content.decode(User.Public.self)
                    #expect(me.name == "Updated")
                }
            )

            let uid = try #require(userId)
            try await app.testing().test(.GET, "users/\(uid.uuidString)", afterResponse: { res async throws in
                #expect(res.status == .ok)
                let p = try res.content.decode(User.PublicProfile.self)
                #expect(p.name == "Updated")
            })

            let reg2 = RegisterRequest(email: "u2@example.com", password: "password12", name: "User Two", avatar: nil)
            try await app.testing().test(.POST, "auth/register", beforeRequest: { req in
                try req.content.encode(reg2)
            }, afterResponse: { res async throws in
                let body = try res.content.decode(AuthTokensResponse.self)
                user2Id = body.user.id
            })

            let u2 = try #require(user2Id)
            try await app.testing().test(
                .POST,
                "users/\(u2.uuidString)/follow",
                headers: ["Authorization": "Bearer \(accessToken)"],
                afterResponse: { res async throws in
                    #expect(res.status == .created || res.status == .ok)
                }
            )

            try await app.testing().test(
                .DELETE,
                "users/\(u2.uuidString)/follow",
                headers: ["Authorization": "Bearer \(accessToken)"],
                afterResponse: { res async throws in
                    #expect(res.status == .noContent)
                }
            )

            try await app.testing().test(.POST, "auth/refresh", beforeRequest: { req in
                try req.content.encode(RefreshRequest(refreshToken: refreshToken))
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let body = try res.content.decode(AuthTokensResponse.self)
                #expect(!body.accessToken.isEmpty)
                refreshToken = body.refreshToken
            })

            try await app.testing().test(.POST, "auth/logout", beforeRequest: { req in
                try req.content.encode(LogoutRequest(refreshToken: refreshToken))
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
            })
        }
    }

    @Test("Login rejects wrong password")
    func loginUnauthorized() async throws {
        try await withApp { app in
            let reg = RegisterRequest(email: "x@example.com", password: "password12", name: "X", avatar: nil)
            try await app.testing().test(.POST, "auth/register", beforeRequest: { req in
                try req.content.encode(reg)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
            })

            try await app.testing().test(.POST, "auth/login", beforeRequest: { req in
                try req.content.encode(LoginRequest(email: "x@example.com", password: "wrongpass"))
            }, afterResponse: { res async throws in
                #expect(res.status == .unauthorized)
            })
        }
    }
}
