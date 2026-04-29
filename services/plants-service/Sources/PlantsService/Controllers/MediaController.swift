import Fluent
import Foundation
import Vapor

enum MediaController {
    static func serve(_ req: Request) async throws -> Response {
        guard let photoID = req.parameters.get("photoID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid photo id")
        }
        guard let meta = try await PhotoMetadata.find(photoID, on: req.db) else {
            throw Abort(.notFound)
        }
        let path = MediaStorage.absoluteURL(for: meta.relativePath, app: req.application).path
        guard FileManager.default.fileExists(atPath: path) else {
            throw Abort(.notFound)
        }
        let parts = meta.mimeType.split(separator: "/")
        guard parts.count == 2 else {
            return try await req.fileio.asyncStreamFile(at: path)
        }
        let mt = HTTPMediaType(type: String(parts[0]), subType: String(parts[1]))
        return try await req.fileio.asyncStreamFile(at: path, mediaType: mt)
    }
}
