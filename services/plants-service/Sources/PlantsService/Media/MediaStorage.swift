import Foundation
import Vapor

enum MediaStorage {
    static func baseDirectory(for app: Application) -> URL {
        let path = Environment.get("MEDIA_PATH") ?? "/tmp/plantio-media"
        return URL(fileURLWithPath: path, isDirectory: true)
    }

    static func ensureBaseExists(for app: Application) throws {
        let dir = baseDirectory(for: app)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    static func absoluteURL(for relativePath: String, app: Application) -> URL {
        baseDirectory(for: app).appendingPathComponent(relativePath)
    }

    static func allowedMimeTypes() -> Set<String> {
        let raw = Environment.get("ALLOWED_MIME_TYPES") ?? "image/jpeg,image/png,image/webp"
        return Set(raw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
    }

    static func maxFileSize() -> Int {
        Int(Environment.get("MAX_FILE_SIZE") ?? "10485760") ?? 10_485_760
    }
}
