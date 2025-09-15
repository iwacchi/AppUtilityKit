// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AppUtilityKit",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(name: "UtilityKit", targets: ["UtilityKit"]),
        .library(name: "AppInfoKit", targets: ["AppInfoKit"]),
        .library(name: "CoreDataKit", targets: ["CoreDataKit"]),
        .library(name: "LoggerKit", targets: ["LoggerKit"]),
        .library(name: "ProductPurchaseKit", targets: ["ProductPurchaseKit"]),
        .library(name: "UserDefaultKit", targets: ["UserDefaultKit"]),
        .library(name: "AppUtilityKitCore", targets: ["AppUtilityKitCore"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "AppUtilityKitCore",
            dependencies: [
                "UtilityKit",
                "AppInfoKit",
                "CoreDataKit",
                "LoggerKit",
                "ProductPurchaseKit",
                "UserDefaultKit",
            ],
            path: "Sources/AppUtilityKitCore"
        ),
        .target(
            name: "UtilityKit",
            path: "Sources/UtilityKit"
        ),
        .target(
            name: "AppInfoKit",
            path: "Sources/AppInfoKit"
        ),
        .target(
            name: "CoreDataKit",
            path: "Sources/CoreDataKit"
        ),
        .target(
            name: "LoggerKit",
            path: "Sources/LoggerKit"
        ),
        .target(
            name: "ProductPurchaseKit",
            path: "Sources/ProductPurchaseKit"
        ),
        .target(
            name: "UserDefaultKit",
            path: "Sources/UserDefaultKit"
        ),
        .testTarget(
            name: "AppUtilityKitTests",
            dependencies: ["AppUtilityKitCore"]
        ),
    ]
)
