import SwiftUI
import WebKit

public enum LeanbackDirection: String, Sendable {
    case up, down, left, right
}

/// Forwards D-pad keys from AppKit into injected leanback JS via evaluateJavaScript.
public final class LeanbackKeyBridge: @unchecked Sendable {
    weak var webView: WKWebView?
    var enabled = false

    public init() {}

    public func move(_ direction: LeanbackDirection) {
        guard enabled, let webView else { return }
        let script = "window.hearthLeanback && hearthLeanback.move('\(direction.rawValue)')"
        MainActor.assumeIsolated {
            webView.evaluateJavaScript(script, completionHandler: nil)
        }
    }

    public func activate() {
        guard enabled, let webView else { return }
        MainActor.assumeIsolated {
            webView.evaluateJavaScript("window.hearthLeanback && hearthLeanback.activate()", completionHandler: nil)
        }
    }

    func scheduleInit() {
        guard enabled, let webView else { return }
        MainActor.assumeIsolated {
            webView.evaluateJavaScript(LeanbackNavigation.initScript, completionHandler: nil)
        }
        for delay in [0.5, 1.5, 3.0] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self, self.enabled, let webView = self.webView else { return }
                webView.evaluateJavaScript(LeanbackNavigation.initScript, completionHandler: nil)
            }
        }
    }
}

public struct StreamingWebView: NSViewRepresentable {
    let url: URL
    let userAgent: String?
    let leanbackEnabled: Bool
    let leanbackAppId: String?
    let isContentFocused: Bool
    let leanbackBridge: LeanbackKeyBridge?
    let additionalUserScripts: [WKUserScript]
    let scriptMessageHandlers: [(name: String, handler: any WKScriptMessageHandler)]
    let onLoadFinished: (@MainActor () -> Void)?

    public init(
        url: URL,
        userAgent: String? = nil,
        leanbackEnabled: Bool = false,
        leanbackAppId: String? = nil,
        isContentFocused: Bool = true,
        leanbackBridge: LeanbackKeyBridge? = nil,
        additionalUserScripts: [WKUserScript] = [],
        scriptMessageHandlers: [(name: String, handler: any WKScriptMessageHandler)] = [],
        onLoadFinished: (@MainActor () -> Void)? = nil
    ) {
        self.url = url
        self.userAgent = userAgent
        self.leanbackEnabled = leanbackEnabled
        self.leanbackAppId = leanbackAppId
        self.isContentFocused = isContentFocused
        self.leanbackBridge = leanbackBridge
        self.additionalUserScripts = additionalUserScripts
        self.scriptMessageHandlers = scriptMessageHandlers
        self.onLoadFinished = onLoadFinished
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(leanbackEnabled: leanbackEnabled, leanbackBridge: leanbackBridge, onLoadFinished: onLoadFinished)
    }

    public func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        if leanbackEnabled {
            configuration.userContentController.addUserScript(LeanbackNavigation.userScript(for: leanbackAppId))
        }
        for script in additionalUserScripts {
            configuration.userContentController.addUserScript(script)
        }
        for handler in scriptMessageHandlers {
            configuration.userContentController.add(handler.handler, name: handler.name)
            context.coordinator.registeredHandlerNames.append(handler.name)
        }

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = false
        webView.allowsMagnification = false

        if let userAgent {
            webView.customUserAgent = userAgent
        }

        context.coordinator.webView = webView
        context.coordinator.contentFocused = isContentFocused
        leanbackBridge?.webView = webView
        leanbackBridge?.enabled = leanbackEnabled
        webView.load(URLRequest(url: url))
        return webView
    }

    public func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.contentFocused = isContentFocused
        leanbackBridge?.webView = webView
        leanbackBridge?.enabled = leanbackEnabled
        if isContentFocused {
            if webView.window?.firstResponder !== webView {
                webView.window?.makeFirstResponder(webView)
            }
        } else if webView.window?.firstResponder === webView {
            webView.window?.makeFirstResponder(nil)
        }
    }

    public static func dismantleNSView(_ webView: WKWebView, coordinator: Coordinator) {
        coordinator.leanbackBridge?.enabled = false
        for name in coordinator.registeredHandlerNames {
            webView.configuration.userContentController.removeScriptMessageHandler(forName: name)
        }
        if webView.window?.firstResponder === webView {
            webView.window?.makeFirstResponder(nil)
        }
    }

    public final class Coordinator: NSObject, WKNavigationDelegate {
        weak var webView: WKWebView?
        var contentFocused = true
        let leanbackEnabled: Bool
        weak var leanbackBridge: LeanbackKeyBridge?
        var registeredHandlerNames: [String] = []
        let onLoadFinished: (@MainActor () -> Void)?

        init(leanbackEnabled: Bool, leanbackBridge: LeanbackKeyBridge?, onLoadFinished: (@MainActor () -> Void)?) {
            self.leanbackEnabled = leanbackEnabled
            self.leanbackBridge = leanbackBridge
            self.onLoadFinished = onLoadFinished
        }

        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            onLoadFinished?()
            if contentFocused {
                webView.window?.makeFirstResponder(webView)
            }
            if leanbackEnabled {
                leanbackBridge?.scheduleInit()
            }
        }
    }
}
