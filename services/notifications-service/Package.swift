// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "notifications-service",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.110.1"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0")
    ],
    targets: [
        .executableTarget(
            name: "NotificationsService",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                .product(name: "JWT", package: "jwt")
            ],
            path: "Sources/NotificationsService"
        ),
        .testTarget(
            name: "NotificationsServiceTests",
            dependencies: [
                .target(name: "NotificationsService"),
                .product(name: "VaporTesting", package: "vapor")
            ],
            path: "Tests/NotificationsServiceTests"
        )
    ],
    swiftLanguageModes: [.v5]
)

