import SwiftUI
import CoreUI
import FeatureApplications
import FeatureStreaming

struct RootView: View {
    @State private var theme = ThemePreferences.theme
    @State private var wallpaper = WallpaperPreferences.style
    @State private var streamingApp: CuratedApp?

    var body: some View {
        ZStack {
            WallpaperBackground(theme: theme, style: wallpaper)

            if streamingApp == nil {
                HomeView(streamingApp: $streamingApp)
                    .environment(\.hearthPalette, theme.palette)
            }

            if let streamingApp {
                StreamingShellView(app: streamingApp) {
                    self.streamingApp = nil
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
