import Foundation
import SwiftData

@Model
public final class FavoriteApp {
    @Attribute(.unique) public var appId: String
    public var pinnedAt: Date

    public init(appId: String, pinnedAt: Date = .now) {
        self.appId = appId
        self.pinnedAt = pinnedAt
    }
}

@Model
public final class RecentApp {
    @Attribute(.unique) public var appId: String
    public var lastLaunchedAt: Date

    public init(appId: String, lastLaunchedAt: Date = .now) {
        self.appId = appId
        self.lastLaunchedAt = lastLaunchedAt
    }
}

@MainActor
public final class AppActivityStore {
    public static let shared = AppActivityStore()

    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    // ponytail: fixed cap; bump or make configurable when recents UI ships (RIS-54)
    private let maxRecentCount = 20

    public init(inMemory: Bool = false) {
        let schema = Schema([FavoriteApp.self, RecentApp.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("AppActivityStore init failed: \(error)")
        }
    }

    public func pinFavorite(appId: String, at date: Date = .now) {
        let appId = appId
        let descriptor = FetchDescriptor<FavoriteApp>(predicate: #Predicate<FavoriteApp> { $0.appId == appId })
        guard (try? context.fetch(descriptor).first) == nil else { return }
        context.insert(FavoriteApp(appId: appId, pinnedAt: date))
        try? context.save()
    }

    public func unpinFavorite(appId: String) {
        let appId = appId
        let descriptor = FetchDescriptor<FavoriteApp>(predicate: #Predicate<FavoriteApp> { $0.appId == appId })
        guard let existing = try? context.fetch(descriptor).first else { return }
        context.delete(existing)
        try? context.save()
    }

    public func isFavorite(appId: String) -> Bool {
        let appId = appId
        let descriptor = FetchDescriptor<FavoriteApp>(predicate: #Predicate<FavoriteApp> { $0.appId == appId })
        return (try? context.fetch(descriptor).first) != nil
    }

    public func favoriteAppIds() -> [String] {
        let descriptor = FetchDescriptor<FavoriteApp>(
            sortBy: [SortDescriptor(\FavoriteApp.pinnedAt, order: .forward)]
        )
        return (try? context.fetch(descriptor))?.map { $0.appId } ?? []
    }

    public func recordLaunch(appId: String, at date: Date = .now) {
        let appId = appId
        let descriptor = FetchDescriptor<RecentApp>(predicate: #Predicate<RecentApp> { $0.appId == appId })
        if let existing = try? context.fetch(descriptor).first {
            existing.lastLaunchedAt = date
        } else {
            context.insert(RecentApp(appId: appId, lastLaunchedAt: date))
        }
        try? context.save()
        trimRecents()
    }

    public func recentAppIds() -> [String] {
        let descriptor = FetchDescriptor<RecentApp>(
            sortBy: [SortDescriptor(\RecentApp.lastLaunchedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor))?.map { $0.appId } ?? []
    }

    private func trimRecents() {
        var descriptor = FetchDescriptor<RecentApp>(
            sortBy: [SortDescriptor(\RecentApp.lastLaunchedAt, order: .reverse)]
        )
        guard let all = try? context.fetch(descriptor), all.count > maxRecentCount else { return }
        for item in all.dropFirst(maxRecentCount) {
            context.delete(item)
        }
        try? context.save()
    }
}
