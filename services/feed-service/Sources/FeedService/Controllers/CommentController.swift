import Fluent
import Vapor

enum CommentController {
    static func index(_ req: Request) async throws -> [CommentDTO] {
        guard let postID = req.parameters.get("postID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid post id")
        }
        guard try await FeedPost.find(postID, on: req.db) != nil else {
            throw Abort(.notFound, reason: "Post not found")
        }
        let comments = try await Comment.query(on: req.db)
            .filter(\.$postID == postID)
            .sort(\.$createdAt, .ascending)
            .all()
        return comments.map(CommentDTO.init(from:))
    }

    static func create(_ req: Request) async throws -> CommentDTO {
        let authorID = try req.requireUserID()
        guard let postID = req.parameters.get("postID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid post id")
        }
        guard let post = try await FeedPost.find(postID, on: req.db) else {
            throw Abort(.notFound, reason: "Post not found")
        }
        let body = try req.content.decode(CreateCommentRequest.self)
        let text = body.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            throw Abort(.badRequest, reason: "text required")
        }

        let comment = Comment(postID: postID, authorUserID: authorID, text: text)
        try await comment.save(on: req.db)

        if post.authorUserID != authorID {
            await req.application.commentPublisher.publishCommentCreated(
                commentID: try comment.requireID(),
                postID: postID,
                postAuthorID: post.authorUserID,
                authorID: authorID,
                text: text,
                client: req.client,
                logger: req.logger
            )
        }

        return CommentDTO(from: comment)
    }

    static func delete(_ req: Request) async throws -> HTTPStatus {
        let authorID = try req.requireUserID()
        guard let postID = req.parameters.get("postID", as: UUID.self),
              let commentID = req.parameters.get("commentID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid id")
        }
        guard let comment = try await Comment.find(commentID, on: req.db),
              comment.postID == postID else {
            throw Abort(.notFound)
        }
        guard comment.authorUserID == authorID else {
            throw Abort(.forbidden, reason: "Cannot delete another user's comment")
        }
        try await comment.delete(on: req.db)
        return .noContent
    }
}
