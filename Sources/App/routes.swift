import Vapor

func routes(_ app: Application) throws {
    
    app.routes.caseInsensitive = true
    
    try app.register(collection: UsersController())
    try app.register(collection: PlantsController())
    try app.register(collection: EventsController())
    try app.register(collection: EventCategoriesController())
    try app.register(collection: PostsController())
}
