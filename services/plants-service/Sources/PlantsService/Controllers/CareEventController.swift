import Fluent
import Vapor

enum CareEventController {
    static func index(_ req: Request) async throws -> [CareEventDTO] {
        let uid = try req.requireUserID()
        guard let plantID = req.parameters.get("plantID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid plant id")
        }
        _ = try await Plant.findOwned(id: plantID, userID: uid, on: req.db)
        let items = try await CareEvent.query(on: req.db)
            .filter(\CareEvent.$plant.$id == plantID)
            .sort(\CareEvent.$occurredAt, .descending)
            .all()
        return items.map(CareEventDTO.init(from:))
    }

    static func create(_ req: Request) async throws -> CareEventDTO {
        let uid = try req.requireUserID()
        guard let plantID = req.parameters.get("plantID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid plant id")
        }
        let plant = try await Plant.findOwned(id: plantID, userID: uid, on: req.db)
        let plantId = try plant.requireID()
        let body = try req.content.decode(CareEventCreateRequest.self)
        let kind = body.kind.trimmingCharacters(in: .whitespacesAndNewlines)
        guard CareEventKind.isValid(kind) else {
            throw Abort(.badRequest, reason: "Invalid kind. Allowed: \(CareEventKind.allValues.joined(separator: ", "))")
        }
        let occurred = body.occurredAt ?? Date()
        let notes = body.notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        let ev = CareEvent(
            plantID: plantId,
            userID: uid,
            kind: kind,
            notes: notes.flatMap { $0.isEmpty ? nil : $0 },
            occurredAt: occurred
        )
        try await ev.save(on: req.db)
        let payload = CareEventCreatedPayload(
            event: "CareEventCreated",
            careEventId: try ev.requireID(),
            plantId: plantId,
            userId: uid,
            kind: kind,
            occurredAt: occurred
        )
        await req.careEventNotifier.publishCareEventCreated(payload, client: req.client, logger: req.logger)
        return CareEventDTO(from: ev)
    }
}
