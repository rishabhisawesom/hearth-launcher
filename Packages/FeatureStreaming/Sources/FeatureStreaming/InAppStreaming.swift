import Foundation

public enum StreamingExperienceKind: Sendable {
    case webShell
    case nativeBrowse
}

public enum InAppStreaming {
    public static func url(for appId: String) -> URL? {
        switch appId {
        case "youtube":
            URL(string: "https://www.youtube.com/tv")
        case "prime-video":
            URL(string: "https://www.primevideo.com/tv")
        default:
            nil
        }
    }

    public static func userAgent(for appId: String) -> String? {
        switch appId {
        case "youtube":
            "Mozilla/5.0 (ChromiumStylePlatform) Cobalt/Version"
        default:
            nil
        }
    }

    public static func leanbackEnabled(for appId: String) -> Bool {
        false
    }

    public static func experienceKind(for appId: String) -> StreamingExperienceKind {
        switch appId {
        case "prime-video":
            .nativeBrowse
        default:
            .webShell
        }
    }
}
