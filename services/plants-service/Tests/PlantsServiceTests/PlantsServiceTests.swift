import JWT
import NIOCore
import Testing
import Vapor
import VaporTesting
@testable import PlantsService

@Suite("Plants Service")
struct PlantsServiceTests {

    private func withApp(_ test: (Application) async throws -> Void) async throws {
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

    private func authHeaders(token: String) -> HTTPHeaders {
        var h = HTTPHeaders()
        h.replaceOrAdd(name: .authorization, value: "Bearer \(token)")
        return h
    }

    private func jsonHeaders(token: String) -> HTTPHeaders {
        var h = authHeaders(token: token)
        h.replaceOrAdd(name: .contentType, value: HTTPMediaType.json.serialize())
        return h
    }

    private func mintAccessToken(app: Application, userId: UUID) throws -> String {
        let payload = AccessTokenPayload(
            subject: SubjectClaim(value: userId.uuidString),
            email: "test@example.com",
            typ: "access",
            exp: ExpirationClaim(value: Date().addingTimeInterval(3600))
        )
        return try app.jwt.signers.sign(payload)
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

    @Test("GET /plants without auth returns 401")
    func plantsRequiresAuth() async throws {
        try await withApp { app in
            try await app.testing().test(.GET, "plants", afterResponse: { res async in
                #expect(res.status == .unauthorized)
            })
        }
    }

    @Test("CRUD plants and care-events with JWT")
    func plantsAndCareEventsFlow() async throws {
        let userId = UUID()
        try await withApp { app in
            let token = try mintAccessToken(app: app, userId: userId)
            let headers = jsonHeaders(token: token)

            let createBody = ByteBuffer(string: #"{"name":"Monstera","species":"M. deliciosa","wateringPeriod":7}"#)

            final class IDBox: @unchecked Sendable {
                var plantId: UUID?
            }
            let box = IDBox()

            try await app.testing().test(.POST, "plants", headers: headers, body: createBody, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let dto = try res.content.decode(PlantDTO.self)
                #expect(dto.userID == userId)
                #expect(dto.name == "Monstera")
                box.plantId = dto.id
            })

            let plantId = try #require(box.plantId)

            try await app.testing().test(.GET, "plants", headers: headers, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let list = try res.content.decode([PlantDTO].self)
                #expect(list.count == 1)
                #expect(list[0].id == plantId)
            })

            try await app.testing().test(.GET, "plants/\(plantId.uuidString)", headers: headers, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let one = try res.content.decode(PlantDTO.self)
                #expect(one.id == plantId)
            })

            let putBody = ByteBuffer(string: #"{"name":"Monstera XL"}"#)
            try await app.testing().test(.PUT, "plants/\(plantId.uuidString)", headers: headers, body: putBody, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let updated = try res.content.decode(PlantDTO.self)
                #expect(updated.name == "Monstera XL")
            })

            let careBody = ByteBuffer(string: #"{"kind":"water"}"#)
            try await app.testing().test(
                .POST,
                "plants/\(plantId.uuidString)/care-events",
                headers: headers,
                body: careBody,
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let ev = try res.content.decode(CareEventDTO.self)
                    #expect(ev.kind == "water")
                    #expect(ev.plantID == plantId)
                }
            )

            try await app.testing().test(.GET, "plants/\(plantId.uuidString)/care-events", headers: headers, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let events = try res.content.decode([CareEventDTO].self)
                #expect(events.count == 1)
                #expect(events[0].kind == "water")
            })

            try await app.testing().test(.DELETE, "plants/\(plantId.uuidString)", headers: headers, afterResponse: { res async throws in
                #expect(res.status == .noContent)
            })
        }
    }
}
