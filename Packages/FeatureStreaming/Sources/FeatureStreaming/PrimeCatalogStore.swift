import Foundation
import Observation

@MainActor
@Observable
public final class PrimeCatalogStore {
    public private(set) var catalog = PrimeCatalog()
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
        CatalogHarvestDebug.write(service: "prime", jsonString: jsonString, sourceURL: sourceURL)

        let trimmed = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("{") || trimmed.hasPrefix("[") else { return }

        responseCount += 1
        loginCheckTask?.cancel()

        let parsed = PrimeCatalogParser.parse(jsonString: jsonString)
        guard !parsed.isEmpty else { return }
        mergeJSON(parsed)
        phase = .ready
        harvestTimeoutTask?.cancel()
    }

    public func ingestDomCatalog(jsonString: String) {
        CatalogHarvestDebug.write(service: "prime-dom", jsonString: jsonString, sourceURL: "domCatalog")

        let parsed = PrimeDOMCatalogParser.parse(jsonString: jsonString)
        guard !parsed.isEmpty else { return }

        responseCount += 1
        loginCheckTask?.cancel()
        mergeDOM(parsed)
        phase = .ready
        harvestTimeoutTask?.cancel()
    }

    private func startHarvestTimeout() {
        harvestTimeoutTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(15))
            guard !Task.isCancelled, phase != .ready else { return }
            if catalog.isEmpty {
                mergeJSON(Self.fallbackCatalog)
            }
            phase = .empty
        }
    }

    private func mergeJSON(_ incoming: PrimeCatalog) {
        var rowsByID = Dictionary(uniqueKeysWithValues: catalog.rows.map { ($0.id, $0) })
        for row in incoming.rows {
            if var existing = rowsByID[row.id] {
                let mergedTiles = dedupeTiles(existing.tiles + row.tiles)
                existing = PrimeRow(id: row.id, title: row.title, tiles: mergedTiles)
                rowsByID[row.id] = existing
            } else {
                rowsByID[row.id] = row
            }
        }
        catalog = PrimeCatalog(rows: Array(rowsByID.values))
    }

    /// DOM-scraped rows replace JSON rows when they carry tiles; JSON-only rows are kept.
    private func mergeDOM(_ incoming: PrimeCatalog) {
        let domTileIDs = Set(incoming.rows.flatMap { $0.tiles.map(\.id) })
        let domRowsByID = Dictionary(
            uniqueKeysWithValues: incoming.rows.filter { !$0.tiles.isEmpty }.map { ($0.id, $0) }
        )

        var merged: [PrimeRow] = Array(domRowsByID.values)
        let domRowIDs = Set(domRowsByID.keys)

        for row in catalog.rows {
            if domRowIDs.contains(row.id) { continue }
            let jsonOnlyTiles = row.tiles.filter { !domTileIDs.contains($0.id) }
            guard !jsonOnlyTiles.isEmpty else { continue }
            merged.append(PrimeRow(id: row.id, title: row.title, tiles: jsonOnlyTiles))
        }

        catalog = PrimeCatalog(rows: merged)
    }

    private func dedupeTiles(_ tiles: [PrimeTile]) -> [PrimeTile] {
        var seen = Set<String>()
        return tiles.filter { tile in
            guard !seen.contains(tile.id) else { return false }
            seen.insert(tile.id)
            return true
        }
    }

    private static let fallbackCatalog = PrimeCatalog(rows: [
        PrimeRow(
            id: "demo-trending",
            title: "Demo — Trending",
            tiles: [
                PrimeTile(
                    id: "demo-boys",
                    title: "The Boys",
                    posterURL: nil,
                    localPosterName: "demo-boys",
                    detailURL: URL(string: "https://www.primevideo.com/detail/0KAJ123")
                ),
                PrimeTile(
                    id: "demo-reacher",
                    title: "Reacher",
                    posterURL: nil,
                    localPosterName: "demo-reacher",
                    detailURL: URL(string: "https://www.primevideo.com/detail/0KAJ456")
                ),
                PrimeTile(
                    id: "demo-fallout",
                    title: "Fallout",
                    posterURL: nil,
                    localPosterName: "demo-fallout",
                    detailURL: URL(string: "https://www.primevideo.com/detail/0KAJ789")
                ),
            ]
        ),
    ])
}
