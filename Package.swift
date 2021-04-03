// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Tree",
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
