import Fluent
import Vapor

enum PlantController {
    static func index(_ req: Request) async throws -> [PlantDTO] {
        let uid = try req.requireUserID()
        // Optional ?userID= query param — lets any authenticated user view another user's plants
        let targetID: UUID
        if let raw = req.query[String.self, at: "userID"], let id = UUID(uuidString: raw) {
            targetID = id
        } else {
            targetID = uid
        }
        let plants = try await Plant.query(on: req.db)
            .filter(\.$userID == targetID)
            .sort(\.$createdAt, .ascending)
            .all()
        return plants.map(PlantDTO.init(from:))
    }

    static func create(_ req: Request) async throws -> PlantDTO {
        let uid = try req.requireUserID()
        let body = try req.content.decode(CreatePlantRequest.self)
        let name = body.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw Abort(.badRequest, reason: "name required") }
        let plant = Plant(
            userID: uid,
            name: name,
            description: body.description?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            species: body.species?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            wateringPeriod: body.wateringPeriod
        )
        try await plant.save(on: req.db)
        return PlantDTO(from: plant)
    }

    static func show(_ req: Request) async throws -> PlantDTO {
        let uid = try req.requireUserID()
        guard let id = req.parameters.get("plantID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid plant id")
        }
        let plant = try await Plant.findOwned(id: id, userID: uid, on: req.db)
        return PlantDTO(from: plant)
    }

    static func update(_ req: Request) async throws -> PlantDTO {
        let uid = try req.requireUserID()
        guard let id = req.parameters.get("plantID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid plant id")
        }
        let plant = try await Plant.findOwned(id: id, userID: uid, on: req.db)
        let body = try req.content.decode(UpdatePlantRequest.self)
        if let n = body.name?.trimmingCharacters(in: .whitespacesAndNewlines), !n.isEmpty {
            plant.name = n
        }
        if let d = body.description {
            plant.description = d.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        }
        if let s = body.species {
            plant.species = s.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        }
        if let w = body.wateringPeriod {
            plant.wateringPeriod = w
        }
        try await plant.save(on: req.db)
        return PlantDTO(from: plant)
    }

    static func delete(_ req: Request) async throws -> HTTPStatus {
        let uid = try req.requireUserID()
        guard let id = req.parameters.get("plantID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid plant id")
        }
        let plant = try await Plant.findOwned(id: id, userID: uid, on: req.db)
        let photos = try await PhotoMetadata.query(on: req.db).filter(\.$plant.$id == id).all()
        let app = req.application
        for p in photos {
            let url = MediaStorage.absoluteURL(for: p.relativePath, app: app)
            try? FileManager.default.removeItem(at: url)
        }
        try await plant.delete(on: req.db)
        return .noContent
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}

extension Plant {
    static func findOwned(id: UUID, userID: UUID, on db: Database) async throws -> Plant {
        guard let p = try await Plant.find(id, on: db), p.userID == userID else {
            throw Abort(.notFound)
        }
        return p
    }
}
