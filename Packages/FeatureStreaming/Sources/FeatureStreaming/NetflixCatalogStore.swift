import Foundation
import Observation

@MainActor
@Observable
public final class NetflixCatalogStore {
    public private(set) var catalog = NetflixCatalog()
    public private(set) var phase: StreamingCatalogPhase = .loading
    public private(set) var responseCount = 0

    public var hasContent: Bool { !catalog.isEmpty }
    public var showsNativeBrowse: Bool { phase == .ready || (phase == .empty && hasContent) }
    public var showsHarvestWebView: Bool { phase != .ready }

    private var loginCheckTask: Task<Void, Never>?
    private var harvestTimeoutTask: Task<Void, Never>?

    public init() {
        startHarvestTimeout()
    }

    public func webViewDidFinishLoad() {
        loginCheckTask?.cancel()
        loginCheckTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled, phase == .loading, responseCount == 0 else { return }
            phase = .needsLogin
        }
    }

    public func ingest(jsonString: String, sourceURL: String) {
        CatalogHarvestDebug.write(service: "netflix", jsonString: jsonString, sourceURL: sourceURL)

        let trimmed = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("{") || trimmed.hasPrefix("[") else { return }

        responseCount += 1
        loginCheckTask?.cancel()

        let parsed = NetflixCatalogParser.parse(jsonString: jsonString)
        guard !parsed.isEmpty else { return }
        merge(parsed)
        phase = .ready
        harvestTimeoutTask?.cancel()
    }

    private func startHarvestTimeout() {
        harvestTimeoutTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(15))
            guard !Task.isCancelled, phase != .ready else { return }
            if catalog.isEmpty {
                merge(Self.fallbackCatalog)
            }
            phase = .empty
        }
    }

    private func merge(_ incoming: NetflixCatalog) {
        var rowsByID = Dictionary(uniqueKeysWithValues: catalog.rows.map { ($0.id, $0) })
        for row in incoming.rows {
            if var existing = rowsByID[row.id] {
                let mergedTiles = dedupeTiles(existing.tiles + row.tiles)
                existing = NetflixRow(id: row.id, title: row.title, tiles: mergedTiles)
                rowsByID[row.id] = existing
            } else {
                rowsByID[row.id] = row
            }
        }
        catalog = NetflixCatalog(rows: Array(rowsByID.values))
    }

    private func dedupeTiles(_ tiles: [NetflixTile]) -> [NetflixTile] {
        var seen = Set<String>()
        return tiles.filter { tile in
            guard !seen.contains(tile.id) else { return false }
            seen.insert(tile.id)
            return true
        }
    }

    private static let fallbackCatalog = NetflixCatalog(rows: [
        NetflixRow(
            id: "demo-trending",
            title: "Demo — Trending",
            tiles: [
                NetflixTile(
                    id: "demo-stranger",
                    title: "Stranger Things",
                    posterURL: nil,
                    localPosterName: "demo-stranger",
                    detailURL: URL(string: "https://www.netflix.com/watch/80057281")
                ),
                NetflixTile(
                    id: "demo-wednesday",
                    title: "Wednesday",
                    posterURL: nil,
                    localPosterName: "demo-wednesday",
                    detailURL: URL(string: "https://www.netflix.com/watch/81231974")
                ),
                NetflixTile(
                    id: "demo-squid",
                    title: "Squid Game",
                    posterURL: nil,
                    localPosterName: "demo-squid",
                    detailURL: URL(string: "https://www.netflix.com/watch/81040344")
                ),
            ]
        ),
    ])
}
