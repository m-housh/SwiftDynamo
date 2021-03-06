// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftDynamo",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "SwiftDynamo",
            targets: ["SwiftDynamo"]),
        .library(
            name: "XCTDynamo",
            targets: ["XCTDynamo"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
         .package(url: "https://github.com/swift-aws/aws-sdk-swift.git", .upToNextMajor(from: "4.0.0")),
         .package(url: "https://github.com/m-housh/DynamoCoder.git", from: "0.1.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SwiftDynamo",
            dependencies: ["DynamoDB", "DynamoCoder"]),
        .target(
            name: "XCTDynamo",
            dependencies: ["SwiftDynamo"]),
        .testTarget(
            name: "SwiftDynamoTests",
            dependencies: ["SwiftDynamo", "XCTDynamo"]),
    ]
)
