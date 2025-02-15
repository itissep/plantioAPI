import Vapor
import Fluent

struct PostsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        
        let routes = routes.grouped("plantio", "posts")
        
        routes.get(use: getAllHandler)
        
        routes.get(":postID", use: getHandler)
        
        routes.get("search", use: searchHandler)
        routes.get("sorted", use: sortedHandler)
        
        routes.get(":postID", "user", use: getUserHandler)
//        routes.get(":postID", "plant", use: getPlantHandler)
        
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        
        let tokenAuthGroup = routes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        tokenAuthGroup.put(":postID", "like", use: likeHandler)
        
        tokenAuthGroup.delete(":postID", use: deleteHandler)
        tokenAuthGroup.post(use: createHandler)
    }
    
    func getAllHandler(_ req: Request) -> EventLoopFuture<[Post]> {
        Post.query(on: req.db).all()
    }
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<Post> {
        let data = try req.content.decode(CreatePostData.self)
        
        let user = try req.auth.require(User.self)
        let Post = try Post(
            title: data.title,
            text: data.text,
            userID: user.requireID(),
            plantID: data.plantID,
            likesUsers: data.likesUsers,
            imagesURLs: data.imagesURLs
        )
        return Post.save(on: req.db).map { Post }
    }
    
    func getHandler(_ req: Request) -> EventLoopFuture<Post> {
        Post.find(req.parameters.get("postID"), on: req.db)
            .unwrap(or: Abort(.notFound))
    }

    func updateHandler(_ req: Request) throws -> EventLoopFuture<Post> {
        let updateData = try req.content.decode(CreatePostData.self)
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        return Post.find(req.parameters.get("postID"), on: req.db)
            .unwrap(or: Abort(.notFound)).flatMap { post in
                post.title = updateData.title
                post.text = updateData.text
                post.likesUsers = updateData.likesUsers
                post.imagesURLs = updateData.imagesURLs
                post.$user.id = userID
                post.$plant.id = updateData.plantID
                return post.save(on: req.db).map {
                    post
                }
            }
    }
    
    func likeHandler(_ req: Request) throws -> EventLoopFuture<Post> {
//        let updateData = try req.content.decode(CreatePostData.self)
        let user = try req.auth.require(User.self)
        let userID = try user.requireID().uuidString
        
        return Post.find(req.parameters.get("postID"), on: req.db)
            .unwrap(or: Abort(.notFound)).flatMap { post in
                post.likesUsers = post.likesUsers + [userID]
                return post.save(on: req.db).map {
                    post
                }
            }
    }
    
    func deleteHandler(_ req: Request)
    -> EventLoopFuture<HTTPStatus> {
        Post.find(req.parameters.get("postID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { Post in
                Post.delete(on: req.db)
                    .transform(to: .noContent)
            }
    }
    
    func searchHandler(_ req: Request) throws -> EventLoopFuture<[Post]> {
        guard let searchTerm = req
            .query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return Post.query(on: req.db).group(.or) { or in
            or.filter(\.$title == searchTerm)
            or.filter(\.$text == searchTerm)
        }.all()
    }
    
    func sortedHandler(_ req: Request) -> EventLoopFuture<[Post]> {
        Post.query(on: req.db).sort(\.$createdAt, .descending).all()
    }
    
    func getUserHandler(_ req: Request) -> EventLoopFuture<User.Public> {
        Post.find(req.parameters.get("postID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { post in
                post.$user.get(on: req.db).convertToPublic()
            }
    }
    
    func getPlantHandler(_ req: Request) -> EventLoopFuture<Plant?> {
        Post.find(req.parameters.get("postID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { post in
                post.$plant.get(on: req.db)
            }
    }
}


struct CreatePostData: Content {
    let title: String
    let text: String
    
    let imagesURLs: [String]
    let likesUsers: [String]
    
    let userID: UUID
    let plantID: UUID?
}
