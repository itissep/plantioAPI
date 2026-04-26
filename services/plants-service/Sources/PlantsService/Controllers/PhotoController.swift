import Fluent
import Foundation
import NIOCore
import Vapor

enum PhotoController {
    static func index(_ req: Request) async throws -> [PhotoDTO] {
        let uid = try req.requireUserID()
        guard let plantID = req.parameters.get("plantID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid plant id")
        }
        _ = try await Plant.findOwned(id: plantID, userID: uid, on: req.db)
        let photos = try await PhotoMetadata.query(on: req.db)
            .filter(\PhotoMetadata.$plant.$id == plantID)
            .sort(\.$createdAt, .descending)
            .all()
        return photos.map(PhotoDTO.init(from:))
    }

    struct UploadInput: Content {
        var file: File
    }

    static func upload(_ req: Request) async throws -> PhotoDTO {
        let uid = try req.requireUserID()
        guard let plantID = req.parameters.get("plantID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid plant id")
        }
        let plant = try await Plant.findOwned(id: plantID, userID: uid, on: req.db)
        let plantId = try plant.requireID()

        let input = try req.content.decode(UploadInput.self)
        let file = input.file
        guard let ct = file.contentType else {
            throw Abort(.badRequest, reason: "Missing content type")
        }
        let mime = ct.serialize()
        guard MediaStorage.allowedMimeTypes().contains(mime) else {
            throw Abort(.unsupportedMediaType, reason: "MIME not allowed")
        }

        var buffer = file.data
        guard buffer.readableBytes <= MediaStorage.maxFileSize() else {
            throw Abort(.payloadTooLarge)
        }

        try MediaStorage.ensureBaseExists(for: req.application)
        let ext = fileExtension(forMime: mime, filename: file.filename)
        let relative = "\(plantId.uuidString)/\(UUID().uuidString).\(ext)"
        let dest = MediaStorage.absoluteURL(for: relative, app: req.application)
        try FileManager.default.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = buffer.readData(length: buffer.readableBytes) ?? Data()
        guard !data.isEmpty else { throw Abort(.badRequest, reason: "Empty file") }
        try data.write(to: dest)

        let meta = PhotoMetadata(
            plantID: plantId,
            userID: uid,
            relativePath: relative,
            mimeType: mime,
            byteSize: data.count
        )
        try await meta.save(on: req.db)
        return PhotoDTO(from: meta)
    }

    static func delete(_ req: Request) async throws -> HTTPStatus {
        let uid = try req.requireUserID()
        guard let plantID = req.parameters.get("plantID", as: UUID.self),
              let photoID = req.parameters.get("photoID", as: UUID.self)
        else {
            throw Abort(.badRequest, reason: "Invalid ids")
        }
        _ = try await Plant.findOwned(id: plantID, userID: uid, on: req.db)
        guard let meta = try await PhotoMetadata.query(on: req.db)
            .filter(\PhotoMetadata.$id == photoID)
            .filter(\PhotoMetadata.$plant.$id == plantID)
            .filter(\PhotoMetadata.$userID == uid)
            .first()
        else {
            throw Abort(.notFound)
        }
        let url = MediaStorage.absoluteURL(for: meta.relativePath, app: req.application)
        try? FileManager.default.removeItem(at: url)
        try await meta.delete(on: req.db)
        return .noContent
    }

    private static func fileExtension(forMime mime: String, filename: String) -> String {
        let ext = (filename as NSString).pathExtension.lowercased()
        if !ext.isEmpty {
            return ext
        }
        if mime == "image/jpeg" { return "jpg" }
        if mime == "image/png" { return "png" }
        if mime == "image/webp" { return "webp" }
        return "bin"
    }
}
