// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Hearth",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "Hearth", targets: ["HearthApp"]),
    ],
    dependencies: [
        .package(path: "Packages/CoreUI"),
        .package(path: "Packages/CoreNavigation"),
        .package(path: "Packages/CoreSystem"),
        .package(path: "Packages/RemoteProtocol"),
        .package(path: "Packages/FeatureApplications"),
    ],
    targets: [
        .executableTarget(
            name: "HearthApp",
            dependencies: [
                "CoreUI",
                "CoreNavigation",
                "CoreSystem",
                "RemoteProtocol",
                "FeatureApplications",
            ]
        ),
    ]
)
