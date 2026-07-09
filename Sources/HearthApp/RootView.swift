import SwiftUI
import CoreUI

struct RootView: View {
    @State private var theme = ThemePreferences.theme
    @State private var wallpaper = WallpaperPreferences.style

    var body: some View {
        ZStack {
            WallpaperBackground(theme: theme, style: wallpaper)

            HomeView()
                .environment(\.hearthPalette, theme.palette)
        }
        .onReceive(NotificationCenter.default.publisher(for: PreferencesDidChange.notification)) { _ in
            theme = ThemePreferences.theme
            wallpaper = WallpaperPreferences.style
        }
    }
}
