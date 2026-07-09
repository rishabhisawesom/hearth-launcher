import AppKit

public enum AppIconProvider {
    public static let fallbackSymbolName = "play.rectangle.fill"
    public static let cacheSize: CGFloat = 128

    // ponytail: in-memory only, no eviction; fine for a handful of curated tiles
    @MainActor private static var cache: [String: NSImage] = [:]

    @MainActor
    public static func icon(for app: CuratedApp) -> NSImage? {
        guard let url = app.resolveURL() else { return nil }
        let key = url.path

        if let cached = cache[key] {
            return cached
        }

        let image = NSWorkspace.shared.icon(forFile: url.path)
        image.size = NSSize(width: cacheSize, height: cacheSize)
        cache[key] = image
        return image
    }
}
