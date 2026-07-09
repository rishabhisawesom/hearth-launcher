import AppKit
import SwiftUI
import CoreSystem

struct SettingsView: View {
    @State private var hideSystemChrome = KioskPreferences.hideSystemChrome
    @State private var launchAtLogin = LoginItem.isRegistered
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
