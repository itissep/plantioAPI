import Fluent
import FluentPostgresDriver
import FluentSQLiteDriver
import JWT
import Vapor

public func configure(_ app: Application) throws {
    let jwtSecret = Environment.get("JWT_SECRET") ?? "local-dev-change-me-min-32-chars!!!!"
    app.jwt.signers.use(.hs256(key: jwtSecret))

    if app.environment == .testing {
        app.databases.use(.sqlite(.memory), as: .sqlite)
    } else {
        let hostname = Environment.get("POSTGRES_HOST") ?? "postgres"
        let username = Environment.get("POSTGRES_USER") ?? "plantio"
        let password = Environment.get("POSTGRES_PASSWORD") ?? "plantio123"
        let dbName = Environment.get("DATABASE_NAME") ?? "plantio_notifications"
        app.databases.use(
            .postgres(
                hostname: hostname,
                username: username,
                password: password,
                database: dbName
            ),
            as: .psql
        )
        app.lifecycle.use(CareEventConsumerLifecycle())
        app.lifecycle.use(CareReminderConsumerLifecycle())
    }

    app.wsManager = WebSocketManager()

    app.migrations.add(CreateNotification())
    try app.autoMigrate().wait()

    try routes(app)
}
