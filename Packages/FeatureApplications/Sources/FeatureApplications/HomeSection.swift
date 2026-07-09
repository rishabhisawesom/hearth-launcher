import Foundation

public struct HomeTile: Identifiable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let app: CuratedApp?

    public init(id: String, title: String, app: CuratedApp? = nil) {
        self.id = id
        self.title = title
        self.app = app
    }
}

public struct HomeSection: Identifiable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let tiles: [HomeTile]

    public init(id: String, title: String, tiles: [HomeTile]) {
        self.id = id
        self.title = title
        self.tiles = tiles
    }
}

public protocol HomeSectionProvider: Sendable {
    var sections: [HomeSection] { get }
}
