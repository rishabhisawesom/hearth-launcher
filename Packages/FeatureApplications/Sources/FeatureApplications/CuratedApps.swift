import Foundation

public struct CuratedApp: Identifiable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let bundleNames: [String]

    public init(id: String, name: String, bundleNames: [String]) {
        self.id = id
        self.name = name
        self.bundleNames = bundleNames
    }

    public func resolveURL() -> URL? {
        let searchPaths = [
            "/Applications",
            NSHomeDirectory() + "/Applications",
        ]

        for basePath in searchPaths {
            for bundleName in bundleNames {
                let url = URL(fileURLWithPath: basePath).appendingPathComponent("\(bundleName).app")
                if FileManager.default.fileExists(atPath: url.path) {
                    return url
                }
            }
        }

        return nil
    }
}

public enum CuratedApps {
    public static let streaming: [CuratedApp] = [
        CuratedApp(id: "netflix", name: "Netflix", bundleNames: ["Netflix"]),
        CuratedApp(id: "prime-video", name: "Prime Video", bundleNames: ["Prime Video", "Amazon Prime Video"]),
        CuratedApp(id: "youtube", name: "YouTube", bundleNames: ["YouTube"]),
        CuratedApp(id: "hotstar", name: "Hotstar", bundleNames: ["Hotstar", "JioHotstar"]),
    ]

    public static func app(id: String) -> CuratedApp? {
        streaming.first { $0.id == id }
    }
}
