import Foundation

/// ponytail: writes last captured harvest payload for manual inspection when catalog stays empty.
public enum CatalogHarvestDebug {
    public static func write(service: String, jsonString: String, sourceURL: String) {
        guard let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return
        }
        let directory = support.appendingPathComponent("Hearth", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let payload: [String: Any] = [
            "url": sourceURL,
            "body": jsonString,
            "capturedAt": ISO8601DateFormatter().string(from: Date()),
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]) else {
            return
        }
        let file = directory.appendingPathComponent("last-harvest-\(service).json")
        try? data.write(to: file, options: .atomic)
    }
}
