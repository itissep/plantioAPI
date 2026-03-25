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

    @Test("POST /auth/register returns 501")
    func registerNotImplemented() async throws {
        try await withApp { app in
            try await app.testing().test(.POST, "auth/register", afterResponse: { res async in
                #expect(res.status == .notImplemented)
            })
        }
    }

    @Test("POST /auth/login returns 501")
    func loginNotImplemented() async throws {
        try await withApp { app in
            try await app.testing().test(.POST, "auth/login", afterResponse: { res async in
                #expect(res.status == .notImplemented)
            })
        }
    }

    @Test("POST /auth/refresh returns 501")
    func refreshNotImplemented() async throws {
        try await withApp { app in
            try await app.testing().test(.POST, "auth/refresh", afterResponse: { res async in
                #expect(res.status == .notImplemented)
            })
        }
    }

    @Test("POST /auth/logout returns 501")
    func logoutNotImplemented() async throws {
        try await withApp { app in
            try await app.testing().test(.POST, "auth/logout", afterResponse: { res async in
                #expect(res.status == .notImplemented)
            })
        }
    }
}
