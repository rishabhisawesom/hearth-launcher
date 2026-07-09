import Foundation

public struct StreamingSectionProvider: HomeSectionProvider, Sendable {
    public init() {}

    public var sections: [HomeSection] {
        [
            HomeSection(
                id: "streaming",
                title: "Streaming",
                tiles: CuratedApps.streaming.map { app in
                    HomeTile(id: app.id, title: app.name, app: app)
                }
            ),
        ]
    }
}
