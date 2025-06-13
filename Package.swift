// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DDDKit",
    platforms: [
        .macOS(.v15),
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
        .library(
            name: "DomainEventGenerator",
            targets: ["DomainEventGenerator"]
        ),
        .library(
            name: "MigrationUtility",
            targets: ["MigrationUtility"]),
       .plugin(name: "DomainEventGeneratorPlugin", targets: [
           "DomainEventGeneratorPlugin"
           
       ]),
       .plugin(name: "ProjectionModelGeneratorPlugin", targets: [
           "ProjectionModelGeneratorPlugin"
       ])
    ],
    dependencies: [
    .package(url: "https://github.com/gradyzhuo/KurrentDB-Swift.git", exact: "1.10.0"),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.5.4"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.1.3")
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
                .product(name: "EventStoreDB", package: "kurrentdb-swift")
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
                .product(name: "EventStoreDB", package: "kurrentdb-swift"),
            ]
        ),
        .target(name: "DomainEventGenerator",
                dependencies: [
                    .product(name: "Yams", package: "yams")
                ]),
        .target(name: "MigrationUtility",
                dependencies: [
                    "DDDCore"
                ]),
        .testTarget(
            name: "DDDCoreTests",
            dependencies: ["DDDKit", "TestUtility", "MigrationUtility"]
        ),
        .executableTarget(name: "generate",
                          dependencies: [
                            "DomainEventGenerator",
                            .product(name: "ArgumentParser", package: "swift-argument-parser")
                          ]),
        .plugin(
          name: "DomainEventGeneratorPlugin",
          capability: .buildTool(),
          dependencies: [
            "generate"
          ]),
        .plugin(
          name: "ProjectionModelGeneratorPlugin",
          capability: .buildTool(),
          dependencies: [
            "generate"
          ]),
        
    ],
    swiftLanguageModes: [
        .v5
    ]
)
