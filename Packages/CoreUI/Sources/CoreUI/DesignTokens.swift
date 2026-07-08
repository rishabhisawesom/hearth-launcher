import SwiftUI

public enum HearthColors {
    public static let background = Color(red: 0.05, green: 0.05, blue: 0.06)
    public static let surface = Color(red: 0.10, green: 0.10, blue: 0.12)
    public static let accent = Color(red: 0.95, green: 0.55, blue: 0.25)
    public static let textPrimary = Color.white
    public static let textSecondary = Color(white: 0.55)
}

public enum HearthTypography {
    public static let title = Font.system(size: 48, weight: .semibold, design: .rounded)
    public static let body = Font.system(size: 24, weight: .medium, design: .rounded)
    public static let caption = Font.system(size: 13, weight: .regular, design: .rounded)
}
