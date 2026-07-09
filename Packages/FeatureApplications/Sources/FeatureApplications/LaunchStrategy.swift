import Foundation

public enum LaunchStrategy: String, CaseIterable, Sendable {
    case preferNativeApp
    case browserOnly
}

public enum LaunchStrategyPreferences {
    private static let key = "launchStrategy"

    public static var strategy: LaunchStrategy {
        get {
            guard let raw = UserDefaults.standard.string(forKey: key),
                  let value = LaunchStrategy(rawValue: raw) else {
                return .preferNativeApp
            }
            return value
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: key)
        }
    }
}

public enum LaunchStrategyResolver {
    public static func launchURL(for app: CuratedApp) -> URL {
        switch LaunchStrategyPreferences.strategy {
        case .preferNativeApp:
            return app.launchURL()
        case .browserOnly:
            return app.webURL
        }
    }
}
