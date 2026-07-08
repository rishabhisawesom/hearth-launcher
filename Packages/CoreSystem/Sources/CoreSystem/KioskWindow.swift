import AppKit
import SwiftUI

public final class KeyableWindow: NSWindow {
    public override var canBecomeKey: Bool { true }
    public override var canBecomeMain: Bool { true }
}

@MainActor
public enum KioskWindow {
    public static func configure(_ window: NSWindow) {
        guard let screen = window.screen ?? NSScreen.main else { return }

        window.styleMask = [.borderless, .fullSizeContentView]
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovable = false
        window.isMovableByWindowBackground = false
        window.collectionBehavior = [.fullScreenPrimary, .canJoinAllSpaces]
        window.backgroundColor = .black
        window.setFrame(screen.frame, display: true)
        window.makeKeyAndOrderFront(nil)
        hideSystemChrome()
    }

    public static func hideSystemChrome() {
        NSApp.activate(ignoringOtherApps: true)
        // ponytail: hide* pair is valid; mixing autoHide* + hide* crashes.
        NSApp.presentationOptions = [.hideMenuBar, .hideDock]
    }
}

public struct KioskWindowConfigurator: NSViewRepresentable {
    public init() {}

    public func makeNSView(context: Context) -> NSView {
        let view = NSView()
        Task { @MainActor in
            guard let window = view.window else { return }
            KioskWindow.configure(window)
        }
        return view
    }

    public func updateNSView(_ nsView: NSView, context: Context) {}
}
