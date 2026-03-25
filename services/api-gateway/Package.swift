// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "api-gateway",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.110.1")
    ],
    targets: [
        .executableTarget(
            name: "APIGateway",
            dependencies: [
                .product(name: "Vapor", package: "vapor")
            ],
            path: "Sources/APIGateway"
        ),
        .testTarget(
            name: "APIGatewayTests",
            dependencies: [
                .target(name: "APIGateway"),
                .product(name: "VaporTesting", package: "vapor")
            ],
            path: "Tests/APIGatewayTests"
        )
    ],
    swiftLanguageModes: [.v5]
)

