// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FeatureApplications",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "FeatureApplications", targets: ["FeatureApplications"]),
    ],
    targets: [
        .target(
            name: "FeatureApplications",
            linkerSettings: [.linkedFramework("SwiftData")]
        ),
        .testTarget(name: "FeatureApplicationsTests", dependencies: ["FeatureApplications"]),
    ]
)
