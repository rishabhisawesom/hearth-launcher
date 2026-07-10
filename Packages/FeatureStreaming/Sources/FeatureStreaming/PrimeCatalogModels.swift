import Foundation

public struct PrimeTile: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let posterURL: URL?
    /// Basename or relative path (under posters/prime/) for a local PNG override.
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

public struct PrimeRow: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let tiles: [PrimeTile]

    public init(id: String, title: String, tiles: [PrimeTile]) {
        self.id = id
        self.title = title
        self.tiles = tiles
    }
}

public struct PrimeCatalog: Equatable, Sendable {
    public var rows: [PrimeRow]

    public init(rows: [PrimeRow] = []) {
        self.rows = rows
    }

    public var isEmpty: Bool { rows.isEmpty }
}
