import Foundation

/// Heuristic JSON walker for Netflix API response shapes (lolomo, bob, graphql, etc.).
/// ponytail: API shapes change; parser is best-effort for personal use only.
public enum NetflixCatalogParser {
    private static let titleKeys = ["title", "name", "displayTitle", "shortName", "synopsis", "headline", "label", "cardTitle"]
    private static let imageKeys = ["boxart", "boxArt", "artwork", "image", "imageUrl", "imageURL", "poster", "src", "url", "backgroundImage", "thumbnail", "packshot"]
    private static let linkKeys = ["href", "detailUrl", "detailURL", "webUrl", "webURL", "link", "url", "canonicalUrl", "watchURL", "watchUrl", "detail", "watch"]
    private static let rowTitleKeys = ["title", "name", "heading", "label", "listName", "rowTitle", "sectionTitle", "genre"]
    private static let detailPathMarkers = ["/watch/", "/title/", "/browse?jbv=", "jbv="]
    private static let rowArrayKeys = ["items", "tiles", "cards", "entities", "contents", "results", "videos", "titles", "list", "lists", "lolomo", "containers"]

    public static func parse(jsonString: String) -> NetflixCatalog {
        guard let data = jsonString.data(using: .utf8) else { return NetflixCatalog() }
        return parse(data: data)
    }

    public static func parse(data: Data) -> NetflixCatalog {
        guard let root = try? JSONSerialization.jsonObject(with: data) else { return NetflixCatalog() }
        var rows: [NetflixRow] = []
        collectRows(from: root, into: &rows)
        if rows.isEmpty {
            let tiles = collectTiles(from: root)
            if !tiles.isEmpty {
                rows.append(NetflixRow(id: "harvested", title: "Browse", tiles: tiles))
            }
        }
        return NetflixCatalog(rows: dedupeRows(rows))
    }

    private static func collectRows(from value: Any, into rows: inout [NetflixRow]) {
        switch value {
        case let dict as [String: Any]:
            if let row = rowFromDictionary(dict) {
                rows.append(row)
            }
            for child in dict.values {
                collectRows(from: child, into: &rows)
            }
        case let array as [Any]:
            if let row = rowFromTileArray(array, fallbackTitle: nil) {
                rows.append(row)
            }
            for child in array {
                collectRows(from: child, into: &rows)
            }
        default:
            break
        }
    }

    private static func rowFromDictionary(_ dict: [String: Any]) -> NetflixRow? {
        let rowTitle = firstString(in: dict, keys: rowTitleKeys)
        for key in rowArrayKeys {
            guard let array = dict[key] as? [Any] else { continue }
            let tiles = array.compactMap { tileFromValue($0) }
            guard tiles.count >= 2 else { continue }
            let title = rowTitle ?? key
            return NetflixRow(id: rowID(title: title, tiles: tiles), title: title, tiles: dedupeTiles(tiles))
        }
        return nil
    }

    private static func rowFromTileArray(_ array: [Any], fallbackTitle: String?) -> NetflixRow? {
        let tiles = array.compactMap { tileFromValue($0) }
        guard tiles.count >= 2 else { return nil }
        let title = fallbackTitle ?? "Browse"
        return NetflixRow(id: rowID(title: title, tiles: tiles), title: title, tiles: dedupeTiles(tiles))
    }

    private static func collectTiles(from value: Any) -> [NetflixTile] {
        var tiles: [NetflixTile] = []
        walk(value) { dict in
            if let tile = tileFromDictionary(dict) {
                tiles.append(tile)
            }
        }
        return dedupeTiles(tiles)
    }

    private static func walk(_ value: Any, visit: ([String: Any]) -> Void) {
        switch value {
        case let dict as [String: Any]:
            visit(dict)
            for child in dict.values { walk(child, visit: visit) }
        case let array as [Any]:
            for child in array { walk(child, visit: visit) }
        default:
            break
        }
    }

    private static func tileFromValue(_ value: Any) -> NetflixTile? {
        guard let dict = value as? [String: Any] else { return nil }
        return tileFromDictionary(dict)
    }

    private static func tileFromDictionary(_ dict: [String: Any]) -> NetflixTile? {
        let title = firstString(in: dict, keys: titleKeys)
        let imageURL = firstURL(in: dict, keys: imageKeys, requireImageHost: true)
        let detailURL = firstDetailURL(in: dict)
        guard let title, !title.isEmpty else { return nil }
        guard imageURL != nil || detailURL != nil else { return nil }
        let id = detailURL?.absoluteString ?? imageURL?.absoluteString ?? title
        return NetflixTile(id: id, title: title, posterURL: imageURL, detailURL: detailURL)
    }

    private static func firstString(in dict: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = dict[key] as? String, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return value.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        for value in dict.values {
            if let nested = value as? [String: Any], let found = firstString(in: nested, keys: keys) {
                return found
            }
        }
        return nil
    }

    private static func firstURL(in dict: [String: Any], keys: [String], requireImageHost: Bool) -> URL? {
        let urls = allURLs(in: dict, keys: keys, requireImageHost: requireImageHost)
        return preferPNG(from: urls)
    }

    private static func allURLs(in dict: [String: Any], keys: [String], requireImageHost: Bool) -> [URL] {
        var urls: [URL] = []
        for key in keys {
            if let value = dict[key] as? String, let url = urlFromString(value, requireImageHost: requireImageHost) {
                urls.append(url)
            }
            if let nested = dict[key] as? [String: Any] {
                urls.append(contentsOf: allURLs(in: nested, keys: keys, requireImageHost: requireImageHost))
            }
        }
        return urls
    }

    private static func preferPNG(from urls: [URL]) -> URL? {
        guard !urls.isEmpty else { return nil }
        if let png = urls.first(where: { $0.pathExtension.lowercased() == "png" }) {
            return png
        }
        return urls.first
    }

    private static func firstDetailURL(in dict: [String: Any]) -> URL? {
        for key in linkKeys {
            if let value = dict[key] as? String, let url = urlFromString(value, requireImageHost: false),
               isDetailURL(url) {
                return url
            }
            if let nested = dict[key] as? [String: Any] {
                for nestedKey in linkKeys {
                    if let value = nested[nestedKey] as? String, let url = urlFromString(value, requireImageHost: false),
                       isDetailURL(url) {
                        return url
                    }
                }
            }
        }
        if let trackId = dict["trackId"] as? Int {
            return URL(string: "https://www.netflix.com/watch/\(trackId)")
        }
        if let videoId = dict["videoId"] as? Int {
            return URL(string: "https://www.netflix.com/watch/\(videoId)")
        }
        return nil
    }

    private static func urlFromString(_ raw: String, requireImageHost: Bool) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let normalized: String
        if trimmed.hasPrefix("//") {
            normalized = "https:" + trimmed
        } else if trimmed.hasPrefix("/") {
            normalized = "https://www.netflix.com" + trimmed
        } else {
            normalized = trimmed
        }
        guard let url = URL(string: normalized) else { return nil }
        if requireImageHost {
            let host = url.host?.lowercased() ?? ""
            let ext = url.pathExtension.lowercased()
            guard host.contains("netflix") || host.contains("nflximg") || host.contains("nflxvideo")
                || ext == "jpg" || ext == "jpeg" || ext == "png" || ext == "webp" || ext == "gif"
            else { return nil }
        }
        return url
    }

    private static func isDetailURL(_ url: URL) -> Bool {
        let absolute = url.absoluteString.lowercased()
        return detailPathMarkers.contains { absolute.contains($0) }
    }

    private static func rowID(title: String, tiles: [NetflixTile]) -> String {
        let prefix = tiles.prefix(3).map(\.id).joined(separator: "|")
        return "\(title)-\(prefix)"
    }

    private static func dedupeTiles(_ tiles: [NetflixTile]) -> [NetflixTile] {
        var seen = Set<String>()
        return tiles.filter { tile in
            guard !seen.contains(tile.id) else { return false }
            seen.insert(tile.id)
            return true
        }
    }

    private static func dedupeRows(_ rows: [NetflixRow]) -> [NetflixRow] {
        var seen = Set<String>()
        return rows.filter { row in
            guard !row.tiles.isEmpty, !seen.contains(row.id) else { return false }
            seen.insert(row.id)
            return true
        }
    }
}
