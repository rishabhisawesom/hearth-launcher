import Foundation

public struct NetflixTile: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let posterURL: URL?
    /// Basename or relative path (under posters/netflix/) for a local PNG override.
    public let localPosterName: String?
    public let detailURL: URL?

    public init(
        id: String,
        title: String,
        posterURL: URL?,
        localPosterName: String? = nil,
        detailURL: URL?
    ) {
        self.id = id
        self.title = title
        self.posterURL = posterURL
        self.localPosterName = localPosterName
        self.detailURL = detailURL
    }
}

public struct NetflixRow: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let tiles: [NetflixTile]

    public init(id: String, title: String, tiles: [NetflixTile]) {
        self.id = id
        self.title = title
        self.tiles = tiles
    }
}

public struct NetflixCatalog: Equatable, Sendable {
    public var rows: [NetflixRow]

    public init(rows: [NetflixRow] = []) {
        self.rows = rows
    }

    public var isEmpty: Bool { rows.isEmpty }
}
