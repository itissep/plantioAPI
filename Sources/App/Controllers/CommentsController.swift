import Vapor
import Fluent

struct CommentsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        
        let routes = routes.grouped("plantio", "comments")
        
        routes.get(use: getAllHandler)
        
        routes.get(":commentID", "post", use: getPostHandler)
        
        //MARK: authed routes
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        
        let tokenAuthGroup = routes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        tokenAuthGroup.put(":commentID", use: updateHandler)
        
        tokenAuthGroup.delete(":commentID", use: deleteHandler)
        
        tokenAuthGroup.post(use: createHandler)
    }
    
    func getAllHandler(_ req: Request) -> EventLoopFuture<[Comment]> {
        Comment.query(on: req.db).all()
    }
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<Comment> {
        let data = try req.content.decode(CreateCommentData.self)
        let comment = Comment(
            text: data.text,
            userID: data.userID,
            postID: data.postID
        )
        return comment.save(on: req.db).map { comment }
    }
    
    func updateHandler(_ req: Request) throws -> EventLoopFuture<Comment> {
        
        let updateData = try req.content.decode(CreateCommentData.self)
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        
        return Comment.find(req.parameters.get("commentID"), on: req.db)
            .unwrap(or: Abort(.notFound)).flatMap { comment in
                comment.text = updateData.text
                comment.$user.id = userID
                comment.$post.id = updateData.postID
                return comment.save(on: req.db).map {
                    comment
                }
            }
    }
    
    func deleteHandler(_ req: Request) -> EventLoopFuture<HTTPStatus> {
        Comment.find(req.parameters.get("commentID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { comment in
                comment.delete(on: req.db)
                    .transform(to: .noContent)
            }
    }
    
    func getFirstHandler(_ req: Request) -> EventLoopFuture<Comment> {
        Comment.query(on: req.db)
            .first()
            .unwrap(or: Abort(.notFound))
    }

    func getPostHandler(_ req: Request) -> EventLoopFuture<Post> {
        Comment.find(req.parameters.get("commentID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { comment in
                comment.$post.get(on: req.db)
            }
    }
    
    func getUserHandler(_ req: Request) -> EventLoopFuture<User.Public> {
        Comment.find(req.parameters.get("commentID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { comment in
                comment.$user.get(on: req.db).convertToPublic()
            }
    }
}

struct CreateCommentData: Content {
    let text: String
    
    let postID: UUID
    let userID: UUID
}
