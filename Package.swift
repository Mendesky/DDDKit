// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DDDKit",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "DDDKit",
            targets: ["DDDKit"]
        ),
        .library(
            name: "TestUtility",
            targets: ["TestUtility"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/gradyzhuo/EventStoreDB-Swift.git", from: "0.2.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.4")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "DDDKit", dependencies: [
                "DDDCore",
                "EventSourcing",
                "ESDBSupport",
                "JBEventBus",
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        .target(
            name: "DDDCore"),
        .target(
            name: "EventSourcing",
            dependencies: [
                "DDDCore",
            ]
        ),
        .target(
            name: "ESDBSupport",
            dependencies: [
                "DDDCore",
                "EventSourcing",
                .product(name: "EventStoreDB", package: "eventstoredb-swift"),
            ]
        ),
        .target(
            name: "JBEventBus",
            dependencies: [
                "DDDCore",
            ]
        ),
        .target(
            name: "TestUtility",
            dependencies: [
                "DDDCore",
                .product(name: "EventStoreDB", package: "eventstoredb-swift"),
            ]
        ),
        .testTarget(
            name: "DDDCoreTests",
            dependencies: ["DDDKit", "TestUtility"]
        ),
    ]
)
