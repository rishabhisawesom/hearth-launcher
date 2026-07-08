import SwiftUI
import CoreUI
import CoreNavigation
import CoreSystem
import RemoteProtocol

@main
struct HearthApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        ZStack {
            HearthColors.background.ignoresSafeArea()
            VStack(spacing: 12) {
                Text("Hearth")
                    .font(HearthTypography.hero)
                    .foregroundStyle(.white)
                Text("Living room launcher")
                    .font(HearthTypography.sectionTitle)
                    .foregroundStyle(HearthColors.accent)
                Text(moduleVersions)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 960, minHeight: 540)
    }

    private var moduleVersions: String {
        "CoreUI \(CoreUI.version) · CoreNavigation \(CoreNavigation.version) · Remote \(RemoteProtocolKit.version)"
    }
}
