import Vapor
import Fluent
import FluentPostgresDriver


public func configure(_ app: Application) async throws {
    app.databases.use(.postgres(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? "vapor_database"
    ), as: .psql)
    
    app.migrations.add(CreateUser())
    app.migrations.add(CreatePlant())
    
    app.logger.logLevel = .debug
    
    try app.autoMigrate().wait()
    try routes(app)
}
