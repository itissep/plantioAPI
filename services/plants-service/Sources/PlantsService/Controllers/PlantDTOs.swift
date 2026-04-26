import Vapor

struct CreatePlantRequest: Content {
    var name: String
    var description: String?
    var species: String?
    var wateringPeriod: Int?
}

struct UpdatePlantRequest: Content {
    var name: String?
    var description: String?
    var species: String?
    var wateringPeriod: Int?
}

struct PlantDTO: Content {
    var id: UUID?
    var userID: UUID
    var name: String
    var description: String?
    var species: String?
    var wateringPeriod: Int?
    var createdAt: Date?
    var updatedAt: Date?

    init(from plant: Plant) {
        self.id = plant.id
        self.userID = plant.userID
        self.name = plant.name
        self.description = plant.description
        self.species = plant.species
        self.wateringPeriod = plant.wateringPeriod
        self.createdAt = plant.createdAt
        self.updatedAt = plant.updatedAt
    }
}

struct CareEventCreateRequest: Content {
    var kind: String
    var notes: String?
    var occurredAt: Date?
}

struct CareEventDTO: Content {
    var id: UUID?
    var plantID: UUID
    var kind: String
    var notes: String?
    var occurredAt: Date
    var createdAt: Date?

    init(from e: CareEvent) {
        self.id = e.id
        self.plantID = e.$plant.id
        self.kind = e.kind
        self.notes = e.notes
        self.occurredAt = e.occurredAt
        self.createdAt = e.createdAt
    }
}

struct PhotoDTO: Content {
    var id: UUID?
    var plantID: UUID
    var mimeType: String
    var byteSize: Int
    var createdAt: Date?

    init(from p: PhotoMetadata) {
        self.id = p.id
        self.plantID = p.$plant.id
        self.mimeType = p.mimeType
        self.byteSize = p.byteSize
        self.createdAt = p.createdAt
    }
}
