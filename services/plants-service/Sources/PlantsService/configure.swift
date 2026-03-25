import Vapor
import Fluent
import FluentPostgresDriver
import FluentSQLiteDriver

public func configure(_ app: Application) throws {
    if app.environment == .testing {
        app.databases.use(.sqlite(.memory), as: .sqlite)
    } else {
        let hostname = Environment.get("POSTGRES_HOST") ?? "postgres"
        let username = Environment.get("POSTGRES_USER") ?? "plantio"
        let password = Environment.get("POSTGRES_PASSWORD") ?? "plantio123"
        let dbName = Environment.get("DATABASE_NAME") ?? "plantio_plants"
        app.databases.use(
            .postgres(
                hostname: hostname,
                username: username,
                password: password,
                database: dbName
            ),
            as: .psql
        )
    }
    try routes(app)
}

