import Foundation

public struct CuratedApp: Identifiable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let bundleNames: [String]
    public let webURL: URL

    public init(id: String, name: String, bundleNames: [String], webURL: URL) {
        self.id = id
        self.name = name
        self.bundleNames = bundleNames
        self.webURL = webURL
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

    /// Native .app when installed, otherwise the streaming web URL.
    public func launchURL() -> URL {
        resolveURL() ?? webURL
    }
}

public enum CuratedApps {
    public static let streaming: [CuratedApp] = [
        CuratedApp(
            id: "netflix",
            name: "Netflix",
            bundleNames: ["Netflix"],
            webURL: URL(string: "https://www.netflix.com")!
        ),
        CuratedApp(
            id: "prime-video",
            name: "Prime Video",
            bundleNames: ["Prime Video", "Amazon Prime Video"],
            webURL: URL(string: "https://www.primevideo.com")!
        ),
        CuratedApp(
            id: "youtube",
            name: "YouTube",
            bundleNames: ["YouTube"],
            webURL: URL(string: "https://www.youtube.com")!
        ),
        CuratedApp(
            id: "hotstar",
            name: "Hotstar",
            bundleNames: ["Hotstar", "JioHotstar"],
            webURL: URL(string: "https://www.hotstar.com")!
        ),
    ]

    public static func app(id: String) -> CuratedApp? {
        streaming.first { $0.id == id }
    }
}
