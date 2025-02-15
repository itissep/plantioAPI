import Vapor

struct EventCategoriesController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {

        let categoriesRoute = routes.grouped("plantio", "eventCategories")

        categoriesRoute.post(use: createHandler)
        categoriesRoute.get(use: getAllHandler)
        categoriesRoute.get(":categoryID", use: getHandler)
        categoriesRoute.get(":categoryID","events", use: getEventsHandler)
    }

    func createHandler(_ req: Request) throws -> EventLoopFuture<EventCategory> {
        let category = try req.content.decode(EventCategory.self)
        return category.save(on: req.db).map { category }
    }

    func getAllHandler(_ req: Request) -> EventLoopFuture<[EventCategory]> {
        EventCategory.query(on: req.db).all()
    }

    func getHandler(_ req: Request) -> EventLoopFuture<EventCategory> {
        EventCategory.find(req.parameters.get("categoryID"), on: req.db)
            .unwrap(or: Abort(.notFound))
    }
    

    func getEventsHandler(_ req: Request) -> EventLoopFuture<[Event]> {
        EventCategory.find(req.parameters.get("categoryID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { category in
                category.$events.get(on: req.db)
            }
    }
}
