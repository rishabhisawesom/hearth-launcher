import AppKit
import SwiftUI
import CoreSystem

@main
struct HearthApp: App {
    @NSApplicationDelegateAdaptor(HearthAppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings { SettingsView() }
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
        window.contentView = NSHostingView(rootView: HomeView())
        KioskWindow.configure(window)
        self.window = window
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        KioskWindow.applySystemChrome()
    }
}
