// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Tree",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
    ],
    products: [
        .library(
            name: "Tree",
            targets: ["Tree"]),
    ],
    targets: [
        .target(
            name: "Tree",
            dependencies: []),
        .testTarget(
            name: "TreeTests",
            dependencies: ["Tree"]),
    ]
)
