import Vapor
import Fluent

struct PlantsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        
        let plantsRoutes = routes.grouped("plantio", "plants")
        
        plantsRoutes.get(use: getAllHandler)
        plantsRoutes.post(use: createHandler)
        plantsRoutes.get(":plantID", use: getHandler)
        plantsRoutes.put(":plantID", use: updateHandler)
        plantsRoutes.delete(":plantID", use: deleteHandler)
        plantsRoutes.get("search", use: searchHandler)
        plantsRoutes.get("first", use: getFirstHandler)
        plantsRoutes.get("sorted", use: sortedHandler)
        
        plantsRoutes.get(":plantID", "user", use: getUserHandler)
    }
    
    func getAllHandler(_ req: Request) -> EventLoopFuture<[Plant]> {
        Plant.query(on: req.db).all()
    }
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<Plant> {
        let data = try req.content.decode(CreatePlantData.self)
        let plant = Plant(name: data.name, desc: data.desc, userID: data.userID)
        return plant.save(on: req.db).map { plant }
    }
    
    func getHandler(_ req: Request) -> EventLoopFuture<Plant> {
        Plant.find(req.parameters.get("plantID"), on: req.db)
            .unwrap(or: Abort(.notFound))
    }
    
    func updateHandler(_ req: Request) throws -> EventLoopFuture<Plant> {
        let updateData = try req.content.decode(CreatePlantData.self)
        return Plant.find(req.parameters.get("plantID"), on: req.db)
            .unwrap(or: Abort(.notFound)).flatMap { plant in
                plant.name = updateData.name
                plant.desc = updateData.desc
                plant.$user.id = updateData.userID
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
    let desc: String
    let userID: UUID
}
