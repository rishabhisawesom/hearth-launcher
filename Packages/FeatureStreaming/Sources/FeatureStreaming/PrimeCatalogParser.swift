import Foundation

/// Heuristic JSON walker for Amazon/Prime API response shapes.
/// ponytail: API shapes change; parser is best-effort for personal use only.
public enum PrimeCatalogParser {
    private static let titleKeys = ["title", "name", "displayTitle", "cardTitle", "heading", "label", "headline"]
    private static let imageKeys = ["imageUrl", "imageURL", "image", "poster", "packshot", "boxArt", "artwork", "src", "url", "backgroundImage", "thumbnail"]
    private static let linkKeys = ["href", "detailUrl", "detailURL", "webUrl", "webURL", "link", "url", "canonicalUrl", "detail", "watch"]
    private static let rowTitleKeys = ["title", "name", "heading", "label", "rowTitle", "sectionTitle"]
    private static let detailPathMarkers = ["/detail/", "/gp/video/detail/", "/watch/"]

    public static func parse(jsonString: String) -> PrimeCatalog {
        guard let data = jsonString.data(using: .utf8) else { return PrimeCatalog() }
        return parse(data: data)
    }

    public static func parse(data: Data) -> PrimeCatalog {
        guard let root = try? JSONSerialization.jsonObject(with: data) else { return PrimeCatalog() }
        var rows: [PrimeRow] = []
        collectRows(from: root, into: &rows)
        if rows.isEmpty {
            let tiles = collectTiles(from: root)
            if !tiles.isEmpty {
                rows.append(PrimeRow(id: "harvested", title: "Browse", tiles: tiles))
            }
        } else {
            let existingIDs = Set(rows.flatMap { $0.tiles.map(\.id) })
            let looseTiles = collectTiles(from: root).filter { !existingIDs.contains($0.id) }
            if !looseTiles.isEmpty {
                rows.append(PrimeRow(id: "more", title: "More", tiles: looseTiles))
            }
        }
        return PrimeCatalog(rows: dedupeRows(rows))
    }

    private static func collectRows(from value: Any, into rows: inout [PrimeRow]) {
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

    private static func rowFromDictionary(_ dict: [String: Any]) -> PrimeRow? {
        let rowTitle = firstString(in: dict, keys: rowTitleKeys)
        let tileArrayKeys = ["items", "tiles", "cards", "entities", "contents", "results", "carouselItems", "titleCards", "containers"]
        for key in tileArrayKeys {
            guard let array = dict[key] as? [Any] else { continue }
            let tiles = array.compactMap { tileFromValue($0) }
            guard tiles.count >= 2 else { continue }
            let title = rowTitle ?? key
            return PrimeRow(id: rowID(title: title, tiles: tiles), title: title, tiles: dedupeTiles(tiles))
        }
        return nil
    }

    private static func rowFromTileArray(_ array: [Any], fallbackTitle: String?) -> PrimeRow? {
        let tiles = array.compactMap { tileFromValue($0) }
        guard tiles.count >= 2 else { return nil }
        let title = fallbackTitle ?? "Browse"
        return PrimeRow(id: rowID(title: title, tiles: tiles), title: title, tiles: dedupeTiles(tiles))
    }

    private static func collectTiles(from value: Any) -> [PrimeTile] {
        var tiles: [PrimeTile] = []
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

    private static func tileFromValue(_ value: Any) -> PrimeTile? {
        guard let dict = value as? [String: Any] else { return nil }
        return tileFromDictionary(dict)
    }

    private static func tileFromDictionary(_ dict: [String: Any]) -> PrimeTile? {
        let title = firstString(in: dict, keys: titleKeys)
        let imageURL = firstURL(in: dict, keys: imageKeys, requireImageHost: true)
        let detailURL = firstDetailURL(in: dict)
        guard let title, !title.isEmpty else { return nil }
        guard imageURL != nil || detailURL != nil else { return nil }
        let id = detailURL?.absoluteString ?? imageURL?.absoluteString ?? title
        return PrimeTile(id: id, title: title, posterURL: imageURL, detailURL: detailURL)
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
        return nil
    }

    private static func urlFromString(_ raw: String, requireImageHost: Bool) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let normalized: String
        if trimmed.hasPrefix("//") {
            normalized = "https:" + trimmed
        } else if trimmed.hasPrefix("/") {
            normalized = "https://www.primevideo.com" + trimmed
        } else {
            normalized = trimmed
        }
        guard let url = URL(string: normalized) else { return nil }
        if requireImageHost {
            let host = url.host?.lowercased() ?? ""
            let ext = url.pathExtension.lowercased()
            guard host.contains("media-amazon") || host.contains("primevideo") || host.contains("ssl-images-amazon")
                || host.contains("amazon")
                || ext == "jpg" || ext == "jpeg" || ext == "png" || ext == "webp" || ext == "gif"
            else { return nil }
        }
        return url
    }

    private static func isDetailURL(_ url: URL) -> Bool {
        let absolute = url.absoluteString.lowercased()
        return detailPathMarkers.contains { absolute.contains($0) }
    }

    private static func rowID(title: String, tiles: [PrimeTile]) -> String {
        let prefix = tiles.prefix(3).map(\.id).joined(separator: "|")
        return "\(title)-\(prefix)"
    }

    private static func dedupeTiles(_ tiles: [PrimeTile]) -> [PrimeTile] {
        var seen = Set<String>()
        return tiles.filter { tile in
            guard !seen.contains(tile.id) else { return false }
            seen.insert(tile.id)
            return true
        }
    }

    private static func dedupeRows(_ rows: [PrimeRow]) -> [PrimeRow] {
        var seen = Set<String>()
        return rows.filter { row in
            guard !row.tiles.isEmpty, !seen.contains(row.id) else { return false }
            seen.insert(row.id)
            return true
        }
    }
}
