import AppKit
import SwiftUI
import CoreUI
import CoreNavigation
import CoreSystem
import RemoteProtocol

@main
struct HearthApp: App {
    @NSApplicationDelegateAdaptor(HearthAppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

@MainActor
final class HearthAppDelegate: NSObject, NSApplicationDelegate {
    private var window: KeyableWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        guard let screen = NSScreen.main else { return }

        let window = KeyableWindow(
            contentRect: screen.frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.contentView = NSHostingView(rootView: ContentView())
        KioskWindow.configure(window)
        self.window = window
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        KioskWindow.hideSystemChrome()
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var moduleVersions: String {
        "CoreUI \(CoreUI.version) · CoreNavigation \(CoreNavigation.version) · Remote \(RemoteProtocolKit.version)"
    }
}
