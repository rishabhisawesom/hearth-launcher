import Foundation

@MainActor
public enum HomeSectionsBuilder {
    public static func build() -> [HomeSection] {
        let candidates = [
            favoritesSection(),
            recentsSection(),
            streamingSection(),
        ].compactMap { $0 }

        return SectionLayoutPreferences.filterAndOrder(candidates)
    }

    private static func favoritesSection() -> HomeSection? {
        let tiles = tiles(for: AppActivityStore.shared.favoriteAppIds())
        guard !tiles.isEmpty else { return nil }
        return HomeSection(id: "favorites", title: "Favorites", tiles: tiles)
    }

    private static func recentsSection() -> HomeSection? {
        let tiles = tiles(for: AppActivityStore.shared.recentAppIds())
        guard !tiles.isEmpty else { return nil }
        return HomeSection(id: "recents", title: "Recently Opened", tiles: tiles)
    }

    private static func streamingSection() -> HomeSection {
        HomeSection(
            id: "streaming",
            title: "Streaming",
            tiles: CuratedApps.streaming.map { app in
                HomeTile(id: app.id, title: app.name, app: app)
            }
        )
    }

    private static func tiles(for appIds: [String]) -> [HomeTile] {
        appIds.compactMap { id in
            guard let app = CuratedApps.app(id: id) else { return nil }
            return HomeTile(id: app.id, title: app.name, app: app)
        }
    }
}
