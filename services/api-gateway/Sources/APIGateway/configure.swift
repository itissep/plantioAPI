import Vapor

public func configure(_ app: Application) throws {
    app.middleware.use(CORSMiddleware(configuration: .default()))

    try routes(app)
}

