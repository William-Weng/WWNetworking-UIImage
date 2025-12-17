// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WWNetworking-UIImage",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "WWNetworking-UIImage", targets: ["WWNetworking-UIImage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/William-Weng/WWSQLite3Manager.git", from: "1.5.2"),
        .package(url: "https://github.com/William-Weng/WWNetworking.git", "1.7.0"..<"1.8.0"),
        .package(url: "https://github.com/William-Weng/WWCacheManager.git", from: "1.0.1"),
    ],
    targets: [
        .target(name: "WWNetworking-UIImage", dependencies: ["WWSQLite3Manager", "WWNetworking", "WWCacheManager"], resources: [.copy("Privacy")]),
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
