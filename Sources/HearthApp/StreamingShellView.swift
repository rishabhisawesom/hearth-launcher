import AppKit
import SwiftUI
import CoreUI
import FeatureApplications
import FeatureStreaming

/// Mutable key-focus state shared with the NSEvent monitor (closures must not capture stale @State).
private final class StreamingKeyContext {
    var webContentFocused = true
    var leanbackEnabled = false
    weak var leanbackBridge: LeanbackKeyBridge?
    var onClose: (() -> Void)?
    var setWebContentFocused: ((Bool) -> Void)?

    func focusBack() {
        guard webContentFocused else { return }
        webContentFocused = false
        setWebContentFocused?(false)
    }

    func focusWeb() {
        guard !webContentFocused else { return }
        webContentFocused = true
        setWebContentFocused?(true)
    }

    func handleLeanbackArrow(keyCode: UInt16) -> Bool {
        guard webContentFocused, leanbackEnabled, let bridge = leanbackBridge else { return false }
        let direction: LeanbackDirection? = switch keyCode {
        case 123: .left
        case 124: .right
        case 125: .down
        case 126: .up
        default: nil
        }
        guard let direction else { return false }
        bridge.move(direction)
        return true
    }

    func handleLeanbackActivate(keyCode: UInt16) -> Bool {
        guard webContentFocused, leanbackEnabled, let bridge = leanbackBridge else { return false }
        guard keyCode == 36 || keyCode == 49 else { return false }
        bridge.activate()
        return true
    }
}

/// Becomes first responder when chrome is focused so WKWebView cannot steal keys.
private struct ChromeFocusBridge: NSViewRepresentable {
    let isActive: Bool

    func makeNSView(context: Context) -> ChromeFocusNSView {
        ChromeFocusNSView()
    }

    func updateNSView(_ nsView: ChromeFocusNSView, context: Context) {
        guard isActive, nsView.window?.firstResponder !== nsView else { return }
        nsView.window?.makeFirstResponder(nsView)
    }
}

private final class ChromeFocusNSView: NSView {
    override var acceptsFirstResponder: Bool { true }
}

struct StreamingShellView: View {
    let app: CuratedApp
    let onClose: () -> Void

    @Environment(\.hearthPalette) private var palette
    @State private var webContentFocused = true
    @State private var leanbackBridge = LeanbackKeyBridge()
    @State private var keyContext = StreamingKeyContext()
    @State private var keyMonitor: Any?

    private var backIsFocused: Bool { !webContentFocused }
    private var leanbackEnabled: Bool { InAppStreaming.leanbackEnabled(for: app.id) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let url = InAppStreaming.url(for: app.id) {
                StreamingWebView(
                    url: url,
                    userAgent: InAppStreaming.userAgent(for: app.id),
                    leanbackEnabled: leanbackEnabled,
                    leanbackAppId: app.id,
                    isContentFocused: webContentFocused,
                    leanbackBridge: leanbackEnabled ? leanbackBridge : nil
                )
                .allowsHitTesting(webContentFocused)
                .ignoresSafeArea()
            }

            backButton
                .padding(HearthSpacing.screenPadding)
                .background {
                    ChromeFocusBridge(isActive: backIsFocused)
                }
        }
        .background(palette.background)
        .onAppear {
            keyContext.webContentFocused = webContentFocused
            keyContext.leanbackEnabled = leanbackEnabled
            keyContext.leanbackBridge = leanbackBridge
            keyContext.onClose = onClose
            keyContext.setWebContentFocused = { webContentFocused = $0 }
            installKeyMonitor()
        }
        .onDisappear {
            removeKeyMonitor()
            NSApp.keyWindow?.makeFirstResponder(nil)
        }
    }

    private var backButton: some View {
        Button(action: onClose) {
            Label("Back", systemImage: "chevron.left")
                .font(HearthTypography.body)
                .foregroundStyle(palette.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(palette.surface.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: HearthRadius.tile))
                .overlay {
                    RoundedRectangle(cornerRadius: HearthRadius.tile)
                        .strokeBorder(backIsFocused ? palette.accent : .clear, lineWidth: 4)
                }
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.15), value: backIsFocused)
    }

    private func installKeyMonitor() {
        let context = keyContext
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            switch event.keyCode {
            case 53: // Escape
                if context.webContentFocused {
                    context.focusBack()
                    return nil
                }
                context.onClose?()
                return nil
            case 51: // Delete / Backspace
                if context.webContentFocused {
                    context.focusBack()
                    return nil
                }
                return event
            case 36: // Return
                if context.handleLeanbackActivate(keyCode: event.keyCode) { return nil }
                guard !context.webContentFocused else { return event }
                context.onClose?()
                return nil
            case 49: // Space
                if context.handleLeanbackActivate(keyCode: event.keyCode) { return nil }
                return event
            case 123, 124, 125, 126: // Arrow keys
                if context.handleLeanbackArrow(keyCode: event.keyCode) { return nil }
                guard !context.webContentFocused else { return event }
                if event.keyCode == 125 {
                    context.focusWeb()
                    return nil
                }
                return event
            default:
                return event
            }
        }
    }

    private func removeKeyMonitor() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
    }
}
