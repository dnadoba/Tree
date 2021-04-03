// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Tree",
    products: [
        .library(
            name: "Tree",
            targets: ["Tree"]),
        .library(
            name: "TreeUI",
            targets: ["TreeUI"]),
    ],
    targets: [
        .target(
            name: "Tree",
            dependencies: []),
        .target(
            name: "TreeUI",
            dependencies: ["Tree"]),
        .testTarget(
            name: "TreeTests",
            dependencies: ["Tree"]),
    ]
)
