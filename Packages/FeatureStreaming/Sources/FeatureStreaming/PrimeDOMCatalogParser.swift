import Foundation

/// Parses `domCatalog` messages scraped from Prime Video card DOM.
public enum PrimeDOMCatalogParser {
    public static func parse(jsonString: String) -> PrimeCatalog {
        guard let data = jsonString.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rowsArray = root["rows"] as? [[String: Any]]
        else { return PrimeCatalog() }

        let rows = rowsArray.compactMap { rowFromDictionary($0) }
        return PrimeCatalog(rows: dedupeRows(rows))
    }

    private static func rowFromDictionary(_ dict: [String: Any]) -> PrimeRow? {
        guard let tilesArray = dict["tiles"] as? [[String: Any]] else { return nil }
        let tiles = tilesArray.compactMap { tileFromDictionary($0) }
        guard !tiles.isEmpty else { return nil }
        let title = (dict["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let rowTitle = (title?.isEmpty == false) ? title! : "Browse"
        return PrimeRow(id: rowID(title: rowTitle, tiles: tiles), title: rowTitle, tiles: dedupeTiles(tiles))
    }

    private static func tileFromDictionary(_ dict: [String: Any]) -> PrimeTile? {
        let title = (dict["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let title, !title.isEmpty else { return nil }
        let posterURL = urlFromString(dict["posterURL"] as? String, requireImageHost: true)
        let detailURL = urlFromString(dict["detailURL"] as? String, requireImageHost: false)
        guard posterURL != nil || detailURL != nil else { return nil }
        let id = detailURL?.absoluteString ?? posterURL?.absoluteString ?? title
        return PrimeTile(id: id, title: title, posterURL: posterURL, detailURL: detailURL)
    }

    private static func urlFromString(_ raw: String?, requireImageHost: Bool) -> URL? {
        guard let raw else { return nil }
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
            guard host.contains("media-amazon") || host.contains("ssl-images-amazon")
                || host.contains("pv-target-images") || host.contains("primevideo")
                || ext == "jpg" || ext == "jpeg" || ext == "png" || ext == "webp"
            else { return nil }
        }
        return url
    }

    private static func rowID(title: String, tiles: [PrimeTile]) -> String {
        let prefix = tiles.prefix(3).map(\.id).joined(separator: "|")
        return "dom-\(title)-\(prefix)"
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
