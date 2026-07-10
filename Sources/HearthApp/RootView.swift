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
                streamingExperience(for: streamingApp)
                    .environment(\.hearthPalette, theme.palette)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: PreferencesDidChange.notification)) { _ in
            theme = ThemePreferences.theme
            wallpaper = WallpaperPreferences.style
        }
    }

    @ViewBuilder
    private func streamingExperience(for app: CuratedApp) -> some View {
        switch InAppStreaming.experienceKind(for: app.id) {
        case .nativeBrowse:
            NetflixExperienceView(app: app) {
                streamingApp = nil
            }
        case .webShell:
            StreamingShellView(app: app) {
                streamingApp = nil
            }
        }
    }
}
