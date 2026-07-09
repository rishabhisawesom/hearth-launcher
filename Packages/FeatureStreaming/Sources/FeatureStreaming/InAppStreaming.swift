import Foundation

public enum InAppStreaming {
    public static func url(for appId: String) -> URL? {
        switch appId {
        case "youtube":
            // ponytail: TV leanback UI; may redirect or block on some UAs — fallback is external launch
            URL(string: "https://www.youtube.com/tv")
        default:
            nil
        }
    }

    /// User-agent hint for leanback web apps that gate on device type.
    public static func userAgent(for appId: String) -> String? {
        switch appId {
        case "youtube":
            "Mozilla/5.0 (ChromiumStylePlatform) Cobalt/Version"
        default:
            nil
        }
    }

    /// Whether to inject spatial D-pad navigation into the web shell.
    public static func leanbackEnabled(for appId: String) -> Bool {
        false
    }
}
