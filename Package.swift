// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WWNetworking-UIImage",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(name: "WWNetworking-UIImage", targets: ["WWNetworking-UIImage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/William-Weng/WWSQLite3Manager.git", from: "1.5.0"),
        .package(url: "https://github.com/William-Weng/WWNetworking.git", from: "1.6.2"),
        .package(url: "https://github.com/William-Weng/WWCacheManager.git", from: "1.0.1"),
    ],
    targets: [
        .target(name: "WWNetworking-UIImage", dependencies: ["WWSQLite3Manager", "WWNetworking", "WWCacheManager"], resources: [.copy("Privacy")]),
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
