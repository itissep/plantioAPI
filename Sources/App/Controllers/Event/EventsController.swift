import Vapor
import Fluent

struct EventsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        
        let routes = routes.grouped("plantio", "events")
        
        routes.get(use: getAllHandler)
        routes.get(":eventID", use: getHandler)
        routes.get("first", use: getFirstHandler)
        routes.get(":eventID", "plant", use: getPlantHandler)
        
        //MARK: authed routes
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        
        let tokenAuthGroup = routes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        tokenAuthGroup.put(":eventID", use: updateHandler)
        tokenAuthGroup.delete(":eventID", use: deleteHandler)
        tokenAuthGroup.post(use: createHandler)
        
        //MARK: categories routes
        tokenAuthGroup.post(":eventID", "categories", ":categoryID", use: addCategoriesHandler)
        routes.get(":eventID", "categories", use: getCategoriesHandler)
        tokenAuthGroup.delete(":eventID", "categories", ":categoryID", use: removeCategoriesHandler)
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
    
    func deleteHandler(_ req: Request) -> EventLoopFuture<HTTPStatus> {
        Event.find(req.parameters.get("eventID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { event in
                event.delete(on: req.db)
                    .transform(to: .noContent)
            }
    }
    
    // MARK: - Categories
    
    func getCategoriesHandler(_ req: Request) -> EventLoopFuture<[EventCategory]> {
        Event.find(req.parameters.get("eventID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { event in
                event.$categories.query(on: req.db).all()
            }
    }
    
    func addCategoriesHandler(_ req: Request)-> EventLoopFuture<HTTPStatus> {
        let eventQuery = Event.find(req.parameters.get("eventID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        let categoryQuery = EventCategory.find(req.parameters.get("categoryID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        return eventQuery.and(categoryQuery)
            .flatMap { event, category in
                event.$categories
                    .attach(category, on: req.db)
                    .transform(to: .created)
            }
    }
    
    func removeCategoriesHandler(_ req: Request) -> EventLoopFuture<HTTPStatus> {
        let eventQuery = Event.find(req.parameters.get("eventID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        let categoryQuery = EventCategory.find(req.parameters.get("categoryID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        return eventQuery.and(categoryQuery)
            .flatMap { event, category in
                event
                    .$categories
                    .detach(category, on: req.db)
                    .transform(to: .noContent)
            }
    }
    
    func getFirstHandler(_ req: Request) -> EventLoopFuture<Event> {
        Event.query(on: req.db)
            .first()
            .unwrap(or: Abort(.notFound))
    }

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
