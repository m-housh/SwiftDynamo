// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TodoApiGateway",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "TodoApiGateway",
            targets: ["TodoApiGateway"]),
        .library(
            name: "TodoService",
            targets: ["TodoService"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/m-housh/SwiftDynamo.git", from: "0.1.1"),
        .package(url: "https://github.com/fabianfett/swift-lambda-runtime.git", from: "0.1.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "TodoApiGateway",
            dependencies: ["TodoService", "LambdaRuntime"]),
        .target(
            name: "TodoService",
            dependencies: ["SwiftDynamo"]),
        .testTarget(
            name: "TodoApiGatewayTests",
            dependencies: ["TodoApiGateway"]),
    ]
)
