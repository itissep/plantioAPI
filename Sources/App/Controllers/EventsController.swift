import Vapor
import Fluent

struct EventsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        
        let routes = routes.grouped("plantio", "events")
        
        routes.get(use: getAllHandler)
        
        routes.get(":eventID", use: getHandler)
        
//        routes.get("search", use: searchHandler)
        routes.get("first", use: getFirstHandler)
//        routes.get("sorted", use: sortedHandler)
        
        routes.get(":eventID", "plant", use: getPlantHandler)
        
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        
        let tokenAuthGroup = routes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        tokenAuthGroup.put(":eventID", use: updateHandler)
        tokenAuthGroup.delete(":eventID", use: deleteHandler)
        tokenAuthGroup.post(use: createHandler)
    }
    
    func getAllHandler(_ req: Request) -> EventLoopFuture<[Event]> {
        Event.query(on: req.db).all()
    }
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<Event> {
        let data = try req.content.decode(CreateEventData.self)

        let Event = Event(
            notes: data.notes,
            plantID: data.plantID
        )
        return Event.save(on: req.db).map { Event }
    }
    
    func getHandler(_ req: Request) -> EventLoopFuture<Event> {
        Event.find(req.parameters.get("eventID"), on: req.db)
            .unwrap(or: Abort(.notFound))
    }
    
    func updateHandler(_ req: Request) throws -> EventLoopFuture<Event> {
        let updateData = try req.content.decode(CreateEventData.self)
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        return Event.find(req.parameters.get("eventID"), on: req.db)
            .unwrap(or: Abort(.notFound)).flatMap { event in
                event.notes = updateData.notes
                event.$plant.id = userID
                return event.save(on: req.db).map {
                    event
                }
            }
    }
    
    func deleteHandler(_ req: Request)
    -> EventLoopFuture<HTTPStatus> {
        Event.find(req.parameters.get("eventID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { Event in
                Event.delete(on: req.db)
                    .transform(to: .noContent)
            }
    }
    
//    func searchHandler(_ req: Request) throws -> EventLoopFuture<[Event]> {
//        guard let searchTerm = req
//            .query[String.self, at: "term"] else {
//            throw Abort(.badRequest)
//        }
//        return Event.query(on: req.db).group(.or) { or in
//            or.filter(\.$name == searchTerm)
//            or.filter(\.$desc == searchTerm)
//        }.all()
//    }
    
    func getFirstHandler(_ req: Request) -> EventLoopFuture<Event> {
        return Event.query(on: req.db)
            .first()
            .unwrap(or: Abort(.notFound))
    }
    
//    func sortedHandler(_ req: Request) -> EventLoopFuture<[Event]> {
//        return Event.query(on: req.db).sort(\.$name, .ascending).all()
//    }
    
    func getPlantHandler(_ req: Request) -> EventLoopFuture<Plant> {
        Event.find(req.parameters.get("eventID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { Event in
                Event.$plant.get(on: req.db)
            }
    }
}


struct CreateEventData: Content {
    let notes: String?
    
    let plantID: UUID
}
