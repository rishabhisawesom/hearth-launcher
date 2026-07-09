import Foundation

public struct SearchResult: Sendable, Equatable {
    public let title: String
    public let app: CuratedApp

    public init(title: String, app: CuratedApp) {
        self.title = title
        self.app = app
    }
}

public enum SearchIndex {
    public static func search(
        _ query: String,
        in apps: [CuratedApp] = CuratedApps.streaming
    ) -> [SearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let needle = trimmed.lowercased()
        return apps.compactMap { app in
            guard app.name.lowercased().contains(needle) else { return nil }
            return SearchResult(title: app.name, app: app)
        }
    }
}
