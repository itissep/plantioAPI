import Vapor
import Fluent
import FluentPostgresDriver
import FluentSQLiteDriver

public func configure(_ app: Application) throws {
    // Database: in-memory SQLite for tests, Postgres otherwise
    if app.environment == .testing {
        app.databases.use(.sqlite(.memory), as: .sqlite)
        app.migrations.add(CreateUser())
        try app.autoMigrate().wait()
    } else {
        let hostname = Environment.get("POSTGRES_HOST") ?? "postgres"
        let username = Environment.get("POSTGRES_USER") ?? "plantio"
        let password = Environment.get("POSTGRES_PASSWORD") ?? "plantio123"
        let dbName = Environment.get("DATABASE_NAME") ?? "plantio_identity"
        app.databases.use(
            .postgres(
                hostname: hostname,
                username: username,
                password: password,
                database: dbName
            ),
            as: .psql
        )
        app.migrations.add(CreateUser())
    }

    try routes(app)
}

