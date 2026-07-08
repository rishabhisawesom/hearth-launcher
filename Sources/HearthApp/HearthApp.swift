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
    private enum Copy {
        static let appName = "Hearth"
        static let tagline = "Living room launcher"
    }

    var body: some View {
        ZStack {
            HearthColors.background.ignoresSafeArea()
            VStack(spacing: 12) {
                Text(Copy.appName)
                    .font(HearthTypography.title)
                    .foregroundStyle(HearthColors.textPrimary)
                Text(Copy.tagline)
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
