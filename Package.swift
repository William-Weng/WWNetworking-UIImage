// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WWNetworking-UIImage",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "WWNetworking-UIImage", targets: ["WWNetworking-UIImage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/William-Weng/WWPrint.git", from: "1.0.1"),
        .package(url: "https://github.com/William-Weng/WWSQLite3Manager.git", from: "1.4.2"),
        .package(url: "https://github.com/William-Weng/WWNetworking.git", from: "1.1.3"),
    ],
    targets: [
        .target(name: "WWNetworking-UIImage", dependencies: ["WWPrint", "WWSQLite3Manager", "WWNetworking"]),
        .testTarget(name: "WWNetworking-UIImageTests", dependencies: ["WWNetworking-UIImage"]),
    ]
)
