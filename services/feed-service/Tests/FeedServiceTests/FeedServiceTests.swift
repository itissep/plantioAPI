import Testing
import VaporTesting
@testable import FeedService

@Suite("Feed Service")
struct FeedServiceTests {

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

    @Test("GET /posts without auth returns 401")
    func postsRequiresAuth() async throws {
        try await withApp { app in
            try await app.testing().test(.GET, "posts", afterResponse: { res async in
                #expect(res.status == .unauthorized)
            })
        }
    }

    @Test("GET /posts/global returns 200")
    func globalFeedPublic() async throws {
        try await withApp { app in
            try await app.testing().test(.GET, "posts/global", afterResponse: { res async in
                #expect(res.status == .ok)
            })
        }
    }
}
