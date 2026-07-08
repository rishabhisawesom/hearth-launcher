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
                    .font(HearthTypography.title)
                    .foregroundStyle(HearthColors.textPrimary)
                Text("Living room launcher")
                    .font(HearthTypography.body)
                    .foregroundStyle(HearthColors.accent)
                Text(moduleVersions)
                    .font(HearthTypography.caption)
                    .foregroundStyle(HearthColors.textSecondary)
            }
        }
        .frame(minWidth: 960, minHeight: 540)
    }

    private var moduleVersions: String {
        "CoreUI \(CoreUI.version) · CoreNavigation \(CoreNavigation.version) · Remote \(RemoteProtocolKit.version)"
    }
}
