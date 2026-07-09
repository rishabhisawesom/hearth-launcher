import SwiftUI

public struct HearthPalette: Equatable, Sendable {
    public let background: Color
    public let surface: Color
    public let accent: Color
    public let textPrimary: Color
    public let textSecondary: Color

    public init(
        background: Color,
        surface: Color,
        accent: Color,
        textPrimary: Color,
        textSecondary: Color
    ) {
        self.background = background
        self.surface = surface
        self.accent = accent
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
    }
}

public enum HearthTheme: String, CaseIterable, Sendable {
    case dark
    case light
    case oled

    public var displayName: String {
        switch self {
        case .dark: "Dark"
        case .light: "Light"
        case .oled: "OLED Dark"
        }
    }

    public var palette: HearthPalette {
        switch self {
        case .dark:
            HearthPalette(
                background: Color(red: 0.05, green: 0.05, blue: 0.06),
                surface: Color(red: 0.10, green: 0.10, blue: 0.12),
                accent: Color(red: 0.95, green: 0.55, blue: 0.25),
                textPrimary: .white,
                textSecondary: Color(white: 0.55)
            )
        case .light:
            HearthPalette(
                background: Color(red: 0.96, green: 0.96, blue: 0.97),
                surface: .white,
                accent: Color(red: 0.85, green: 0.40, blue: 0.12),
                textPrimary: Color(red: 0.08, green: 0.08, blue: 0.10),
                textSecondary: Color(white: 0.40)
            )
        case .oled:
            HearthPalette(
                background: .black,
                surface: Color(red: 0.06, green: 0.06, blue: 0.06),
                accent: Color(red: 0.95, green: 0.55, blue: 0.25),
                textPrimary: .white,
                textSecondary: Color(white: 0.55)
            )
        }
    }
}

public enum WallpaperStyle: String, CaseIterable, Sendable {
    case none
    case gradient

    public var displayName: String {
        switch self {
        case .none: "Solid"
        case .gradient: "Gradient"
        }
    }
}

public enum ThemePreferences {
    private static let themeKey = "hearth.theme"

    public static var theme: HearthTheme {
        get {
            guard let raw = UserDefaults.standard.string(forKey: themeKey),
                  let theme = HearthTheme(rawValue: raw) else { return .dark }
            return theme
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: themeKey)
            PreferencesDidChange.notify()
        }
    }
}

public enum WallpaperPreferences {
    private static let styleKey = "hearth.wallpaper"

    public static var style: WallpaperStyle {
        get {
            guard let raw = UserDefaults.standard.string(forKey: styleKey),
                  let style = WallpaperStyle(rawValue: raw) else { return .gradient }
            return style
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: styleKey)
            PreferencesDidChange.notify()
        }
    }
}

public enum PreferencesDidChange {
    public static let notification = Notification.Name("hearth.preferencesDidChange")

    public static func notify() {
        NotificationCenter.default.post(name: notification, object: nil)
    }
}

private struct HearthPaletteKey: EnvironmentKey {
    static let defaultValue = HearthTheme.dark.palette
}

public extension EnvironmentValues {
    var hearthPalette: HearthPalette {
        get { self[HearthPaletteKey.self] }
        set { self[HearthPaletteKey.self] = newValue }
    }
}
