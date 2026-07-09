// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FeatureStreaming",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "FeatureStreaming", targets: ["FeatureStreaming"]),
    ],
    targets: [
        .target(
            name: "FeatureStreaming",
            linkerSettings: [.linkedFramework("WebKit")]
        ),
        .testTarget(
            name: "FeatureStreamingTests",
            dependencies: ["FeatureStreaming"],
            resources: [.process("Fixtures")]
        ),
    ]
)
