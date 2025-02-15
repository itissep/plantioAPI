import Vapor
import Fluent

struct PlantsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        
        let plantsRoutes = routes.grouped("plantio", "plants")
        
        plantsRoutes.get(use: getAllHandler)
        
        plantsRoutes.get(":plantID", use: getHandler)
        
        plantsRoutes.get("search", use: searchHandler)
        plantsRoutes.get("first", use: getFirstHandler)
        plantsRoutes.get("sorted", use: sortedHandler)
        
        plantsRoutes.get(":plantID", "user", use: getUserHandler)
        plantsRoutes.get(":plantID", "events", use: getEventsHandler)
        
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        
        let tokenAuthGroup = plantsRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        tokenAuthGroup.put(":plantID", use: updateHandler)
        tokenAuthGroup.delete(":plantID", use: deleteHandler)
        tokenAuthGroup.post(use: createHandler)
    }
    
    func getAllHandler(_ req: Request) -> EventLoopFuture<[Plant]> {
        Plant.query(on: req.db).all()
    }
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<Plant> {
        let data = try req.content.decode(CreatePlantData.self)
        
        
        let user = try req.auth.require(User.self)
        let plant = try Plant(
            name: data.name,
            desc: data.desc,
            userID: user.requireID(),
            wateringPeriod: data.wateringPeriod,
            type: data.type
        )
        return plant.save(on: req.db).map { plant }
    }
    
    func getHandler(_ req: Request) -> EventLoopFuture<Plant> {
        Plant.find(req.parameters.get("plantID"), on: req.db)
            .unwrap(or: Abort(.notFound))
    }
    
    func getEventsHandler(_ req: Request) -> EventLoopFuture<[Event]> {
        Plant.find(req.parameters.get("plantID"), on: req.db).unwrap(or: Abort(.notFound)).flatMap { plant in
            plant.$events.get(on: req.db)
        }
    }
    
    func updateHandler(_ req: Request) throws -> EventLoopFuture<Plant> {
        let updateData = try req.content.decode(CreatePlantData.self)
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        return Plant.find(req.parameters.get("plantID"), on: req.db)
            .unwrap(or: Abort(.notFound)).flatMap { plant in
                plant.name = updateData.name
                plant.desc = updateData.desc
                plant.type = updateData.type
                plant.wateringPeriod = updateData.wateringPeriod
                plant.$user.id = userID
                return plant.save(on: req.db).map {
                    plant
                }
            }
    }
    
    func deleteHandler(_ req: Request)
    -> EventLoopFuture<HTTPStatus> {
        Plant.find(req.parameters.get("plantID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { Plant in
                Plant.delete(on: req.db)
                    .transform(to: .noContent)
            }
    }
    
    func searchHandler(_ req: Request) throws -> EventLoopFuture<[Plant]> {
        guard let searchTerm = req
            .query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return Plant.query(on: req.db).group(.or) { or in
            or.filter(\.$name == searchTerm)
            or.filter(\.$desc == searchTerm)
        }.all()
    }
    
    func getFirstHandler(_ req: Request) -> EventLoopFuture<Plant> {
        return Plant.query(on: req.db)
            .first()
            .unwrap(or: Abort(.notFound))
    }
    
    func sortedHandler(_ req: Request) -> EventLoopFuture<[Plant]> {
        return Plant.query(on: req.db).sort(\.$name, .ascending).all()
    }
    
    func getUserHandler(_ req: Request) -> EventLoopFuture<User.Public> {
        Plant.find(req.parameters.get("plantID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { plant in
                plant.$user.get(on: req.db).convertToPublic()
            }
    }
}


struct CreatePlantData: Content {
    let name: String
    let desc: String?
    let type: String?
    let wateringPeriod: Int?
    
    let userID: UUID
}
