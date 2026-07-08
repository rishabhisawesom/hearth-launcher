import AppKit

public final class KeyableWindow: NSWindow {
    public override var canBecomeKey: Bool { true }
    public override var canBecomeMain: Bool { true }
}

@MainActor
public enum KioskWindow {
    public static func configure(_ window: NSWindow, hideChrome: Bool = true) {
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
        if hideChrome {
            hideSystemChrome()
        }
    }

    public static func hideSystemChrome() {
        NSApp.activate(ignoringOtherApps: true)
        // ponytail: hide* pair is valid; mixing autoHide* + hide* crashes.
        NSApp.presentationOptions = [.hideMenuBar, .hideDock]
    }
}
