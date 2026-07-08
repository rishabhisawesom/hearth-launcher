// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RemoteProtocol",
    platforms: [.macOS(.v15), .iOS(.v17)],
    products: [
        .library(name: "RemoteProtocol", targets: ["RemoteProtocol"]),
    ],
    targets: [
        .target(name: "RemoteProtocol"),
        .testTarget(name: "RemoteProtocolTests", dependencies: ["RemoteProtocol"]),
    ]
)
