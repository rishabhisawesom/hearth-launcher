import SwiftUI
import CoreUI
import FeatureApplications

struct RootView: View {
    @State private var theme = ThemePreferences.theme
    @State private var wallpaper = WallpaperPreferences.style
    @State private var searchPresented = false

    var body: some View {
        ZStack {
            WallpaperBackground(theme: theme, style: wallpaper)

            HomeView(searchPresented: $searchPresented)
                .environment(\.hearthPalette, theme.palette)

            if searchPresented {
                SearchOverlayView(isPresented: $searchPresented) { app in
                    _ = AppLauncher.launch(app)
                }
                .environment(\.hearthPalette, theme.palette)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: PreferencesDidChange.notification)) { _ in
            theme = ThemePreferences.theme
            wallpaper = WallpaperPreferences.style
        }
    }
}
