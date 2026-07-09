import Foundation

// ponytail: JSON file persistence instead of SwiftData — builds with Command Line Tools (no macro plugin)

private struct FavoriteEntry: Codable, Equatable {
    let appId: String
    let pinnedAt: Date
}

private struct RecentEntry: Codable, Equatable {
    let appId: String
    var lastLaunchedAt: Date
}

private struct AppActivityData: Codable, Equatable {
    var favorites: [FavoriteEntry]
    var recents: [RecentEntry]
}

@MainActor
public final class AppActivityStore {
    public static let shared = AppActivityStore()

    private let fileURL: URL?
    private var data: AppActivityData

    // ponytail: fixed cap; bump or make configurable when recents UI ships (RIS-54)
    private let maxRecentCount = 20

    public init(inMemory: Bool = false) {
        if inMemory {
            fileURL = nil
            data = AppActivityData(favorites: [], recents: [])
        } else {
            let url = Self.defaultFileURL()
            fileURL = url
            data = Self.load(from: url) ?? AppActivityData(favorites: [], recents: [])
        }
    }

    public func pinFavorite(appId: String, at date: Date = .now) {
        guard !data.favorites.contains(where: { $0.appId == appId }) else { return }
        data.favorites.append(FavoriteEntry(appId: appId, pinnedAt: date))
        data.favorites.sort { $0.pinnedAt < $1.pinnedAt }
        persist()
    }

    public func unpinFavorite(appId: String) {
        data.favorites.removeAll { $0.appId == appId }
        persist()
    }

    public func isFavorite(appId: String) -> Bool {
        data.favorites.contains { $0.appId == appId }
    }

    public func favoriteAppIds() -> [String] {
        data.favorites.map(\.appId)
    }

    public func recordLaunch(appId: String, at date: Date = .now) {
        if let index = data.recents.firstIndex(where: { $0.appId == appId }) {
            data.recents[index].lastLaunchedAt = date
        } else {
            data.recents.append(RecentEntry(appId: appId, lastLaunchedAt: date))
        }
        data.recents.sort { $0.lastLaunchedAt > $1.lastLaunchedAt }
        trimRecents()
        persist()
    }

    public func recentAppIds() -> [String] {
        data.recents.map(\.appId)
    }

    private func trimRecents() {
        guard data.recents.count > maxRecentCount else { return }
        data.recents = Array(data.recents.prefix(maxRecentCount))
    }

    private func persist() {
        guard let fileURL else { return }
        Self.save(data, to: fileURL)
    }

    private static func defaultFileURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("Hearth", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("app-activity.json")
    }

    private static func load(from url: URL) -> AppActivityData? {
        guard let bytes = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(AppActivityData.self, from: bytes)
    }

    private static func save(_ data: AppActivityData, to url: URL) {
        guard let bytes = try? JSONEncoder().encode(data) else { return }
        try? bytes.write(to: url, options: .atomic)
    }
}
