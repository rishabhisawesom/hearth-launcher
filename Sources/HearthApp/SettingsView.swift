import AppKit
import SwiftUI
import CoreSystem
import FeatureApplications

struct SettingsView: View {
    @State private var hideSystemChrome = KioskPreferences.hideSystemChrome
    @State private var launchAtLogin = LoginItem.isRegistered
    @State private var sectionOrder = SectionLayoutPreferences.order
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

            Section("Favorites") {
                ForEach(CuratedApps.streaming) { app in
                    Toggle(app.name, isOn: favoriteBinding(for: app.id))
                }
            }

            Section("Home sections") {
                ForEach(sectionOrder, id: \.self) { sectionId in
                    HStack {
                        Toggle(SectionLayoutPreferences.title(for: sectionId), isOn: visibilityBinding(for: sectionId))
                        Spacer()
                        if sectionOrder.first != sectionId {
                            Button { moveSection(sectionId, offset: -1) } label: {
                                Image(systemName: "chevron.up")
                            }
                            .buttonStyle(.borderless)
                        }
                        if sectionOrder.last != sectionId {
                            Button { moveSection(sectionId, offset: 1) } label: {
                                Image(systemName: "chevron.down")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
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
        .formStyle(.grouped)
        .padding()
        .frame(width: 420)
    }

    private func moveSection(_ sectionId: String, offset: Int) {
        guard let index = sectionOrder.firstIndex(of: sectionId) else { return }
        let newIndex = index + offset
        guard sectionOrder.indices.contains(newIndex) else { return }
        sectionOrder.swapAt(index, newIndex)
        SectionLayoutPreferences.order = sectionOrder
    }

    private func favoriteBinding(for appId: String) -> Binding<Bool> {
        Binding(
            get: { AppActivityStore.shared.isFavorite(appId: appId) },
            set: { enabled in
                if enabled {
                    AppActivityStore.shared.pinFavorite(appId: appId)
                } else {
                    AppActivityStore.shared.unpinFavorite(appId: appId)
                }
            }
        )
    }

    private func visibilityBinding(for sectionId: String) -> Binding<Bool> {
        Binding(
            get: { SectionLayoutPreferences.isVisible(sectionId) },
            set: { SectionLayoutPreferences.setVisible(sectionId, $0) }
        )
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
