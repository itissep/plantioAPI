// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "feed-service",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.110.1"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0")
    ],
    targets: [
        .executableTarget(
            name: "FeedService",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver")
            ]
        ),
        .testTarget(
            name: "FeedServiceTests",
            dependencies: [
                .target(name: "FeedService"),
                .product(name: "VaporTesting", package: "vapor")
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)

