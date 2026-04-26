import Fluent
import Vapor

enum FeedController {
    static func index(_ req: Request) async throws -> [FeedPostDTO] {
        let userID = try req.requireUserID()
        let page = req.query[Int.self, at: "page"] ?? 1
        let perPage = min(req.query[Int.self, at: "perPage"] ?? 20, 100)
        let offset = (page - 1) * perPage

        let posts = try await FeedPost.query(on: req.db)
            .filter(\.$ownerUserID == userID)
            .filter(\.$isGlobal == false)
            .sort(\.$occurredAt, .descending)
            .range(offset..<(offset + perPage))
            .all()

        return posts.map(FeedPostDTO.init(from:))
    }

    static func global(_ req: Request) async throws -> [FeedPostDTO] {
        let page = req.query[Int.self, at: "page"] ?? 1
        let perPage = min(req.query[Int.self, at: "perPage"] ?? 20, 100)
        let offset = (page - 1) * perPage

        let posts = try await FeedPost.query(on: req.db)
            .filter(\.$isGlobal == true)
            .sort(\.$occurredAt, .descending)
            .range(offset..<(offset + perPage))
            .all()

        return posts.map(FeedPostDTO.init(from:))
    }
}
