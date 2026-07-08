// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CoreSystem",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "CoreSystem", targets: ["CoreSystem"]),
    ],
    targets: [
        .target(name: "CoreSystem"),
        .testTarget(name: "CoreSystemTests", dependencies: ["CoreSystem"]),
    ]
)
