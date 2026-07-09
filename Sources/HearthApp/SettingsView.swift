import AppKit
import SwiftUI
import CoreSystem
import CoreUI
import FeatureApplications

struct SettingsView: View {
    @State private var hideSystemChrome = KioskPreferences.hideSystemChrome
    @State private var launchAtLogin = LoginItem.isRegistered
    @State private var launchStrategy = LaunchStrategyPreferences.strategy
    @State private var theme = ThemePreferences.theme
    @State private var wallpaper = WallpaperPreferences.style
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Toggle("Hide Dock and menu bar", isOn: $hideSystemChrome)
                .onChange(of: hideSystemChrome) { _, newValue in
                    KioskPreferences.hideSystemChrome = newValue
                    KioskWindow.applySystemChrome()
                }

            Toggle("Launch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    updateLoginItem(enabled: newValue)
                }

            Picker("Streaming launch", selection: $launchStrategy) {
                Text("Prefer app, else browser").tag(LaunchStrategy.preferNativeApp)
                Text("Browser only").tag(LaunchStrategy.browserOnly)
            }
            .onChange(of: launchStrategy) { _, newValue in
                LaunchStrategyPreferences.strategy = newValue
            }

            Picker("Theme", selection: $theme) {
                ForEach(HearthTheme.allCases, id: \.self) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .onChange(of: theme) { _, newValue in
                ThemePreferences.theme = newValue
            }

            Picker("Wallpaper", selection: $wallpaper) {
                ForEach(WallpaperStyle.allCases, id: \.self) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .onChange(of: wallpaper) { _, newValue in
                WallpaperPreferences.style = newValue
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Button("Quit Hearth") {
                NSApp.terminate(nil)
            }
        }
        .padding()
        .frame(width: 420)
    }

    private func updateLoginItem(enabled: Bool) {
        do {
            try LoginItem.setEnabled(enabled)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            launchAtLogin = LoginItem.isRegistered
        }
    }
}
