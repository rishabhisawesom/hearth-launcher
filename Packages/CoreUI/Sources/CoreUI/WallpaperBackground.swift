import SwiftUI

public struct WallpaperBackground: View {
    let theme: HearthTheme
    let style: WallpaperStyle

    public init(theme: HearthTheme, style: WallpaperStyle) {
        self.theme = theme
        self.style = style
    }

    public var body: some View {
        ZStack {
            theme.palette.background
            if style == .gradient {
                gradientLayer
            }
        }
        .ignoresSafeArea()
    }

    private var gradientLayer: some View {
        // ponytail: static gradient only; parallax deferred until focus-driven motion is needed
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .opacity(0.55)
        .blur(radius: 48)
    }

    private var gradientColors: [Color] {
        switch theme {
        case .dark:
            [
                Color(red: 0.15, green: 0.08, blue: 0.35),
                Color(red: 0.05, green: 0.12, blue: 0.28),
                theme.palette.background,
            ]
        case .light:
            [
                Color(red: 0.75, green: 0.85, blue: 1.0),
                Color(red: 0.95, green: 0.88, blue: 0.78),
                theme.palette.background,
            ]
        case .oled:
            [
                Color(red: 0.12, green: 0.04, blue: 0.22),
                Color(red: 0.02, green: 0.08, blue: 0.18),
                .black,
            ]
        }
    }
}
