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
            ]
        ),
        .testTarget(
            name: "APIGatewayTests",
            dependencies: [
                .target(name: "APIGateway"),
                .product(name: "VaporTesting", package: "vapor")
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)

