import Foundation
import WebKit

/// Injects fetch/XHR hooks and forwards Netflix API JSON blobs to Swift.
/// ponytail: host + JSON heuristics; Netflix changes endpoints without notice.
public enum NetflixCatalogHarvester {
    public static let messageHandlerName = "hearthNetflix"

    @MainActor
    public static var userScript: WKUserScript {
        let source = """
        (function () {
          if (window.hearthNetflixHarvester) return;

          var HOSTS = [/netflix\\.com/i, /nflxvideo\\.net/i, /nflximg\\.net/i];
          function onHost(url) {
            if (!url) return false;
            try {
              var host = new URL(String(url), window.location.href).hostname;
              return HOSTS.some(function (re) { return re.test(host); });
            } catch (e) {
              return false;
            }
          }

          function looksLikeJSON(text, contentType) {
            if (contentType && /json/i.test(contentType)) return true;
            if (!text || text.length < 1024) return false;
            var t = String(text).trim();
            return t.charAt(0) === '{' || t.charAt(0) === '[';
          }

          function post(body, url) {
            try {
              window.webkit.messageHandlers.\(messageHandlerName).postMessage({
                url: url,
                body: typeof body === 'string' ? body : JSON.stringify(body)
              });
            } catch (e) {}
          }

          var origFetch = window.fetch;
          window.fetch = function () {
            var args = arguments;
            var reqUrl = '';
            if (typeof args[0] === 'string') reqUrl = args[0];
            else if (args[0] && args[0].url) reqUrl = args[0].url;
            return origFetch.apply(this, args).then(function (response) {
              if (onHost(reqUrl)) {
                try {
                  var ct = response.headers && response.headers.get ? response.headers.get('content-type') : '';
                  response.clone().text().then(function (text) {
                    if (looksLikeJSON(text, ct)) post(text, reqUrl);
                  });
                } catch (e) {}
              }
              return response;
            });
          };

          var origOpen = XMLHttpRequest.prototype.open;
          var origSend = XMLHttpRequest.prototype.send;
          XMLHttpRequest.prototype.open = function (method, url) {
            this._hearthNetflixUrl = url;
            return origOpen.apply(this, arguments);
          };
          XMLHttpRequest.prototype.send = function () {
            var xhr = this;
            xhr.addEventListener('load', function () {
              try {
                var ct = xhr.getResponseHeader ? xhr.getResponseHeader('content-type') : '';
                if (onHost(xhr._hearthNetflixUrl) && looksLikeJSON(xhr.responseText, ct)) {
                  post(xhr.responseText, xhr._hearthNetflixUrl);
                }
              } catch (e) {}
            });
            return origSend.apply(this, arguments);
          };

          window.hearthNetflixHarvester = { ready: true };
        })();
        """
        return WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: false)
    }

    @MainActor
    public static func makeMessageHandler(onPayload: @escaping @Sendable (String, String) -> Void) -> NetflixCatalogMessageHandler {
        NetflixCatalogMessageHandler(onPayload: onPayload)
    }
}

@MainActor
public final class NetflixCatalogMessageHandler: NSObject, WKScriptMessageHandler {
    public var onPayload: @Sendable (String, String) -> Void

    public init(onPayload: @escaping @Sendable (String, String) -> Void) {
        self.onPayload = onPayload
    }

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == NetflixCatalogHarvester.messageHandlerName,
              let body = message.body as? [String: Any],
              let jsonString = body["body"] as? String,
              let sourceURL = body["url"] as? String
        else { return }
        onPayload(jsonString, sourceURL)
    }
}
