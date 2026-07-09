import Foundation
import WebKit

/// Injects fetch/XHR hooks, DOM card scraper, and forwards Prime catalog data to Swift.
/// ponytail: host + JSON heuristics; Amazon changes endpoints without notice.
public enum PrimeCatalogHarvester {
    public static let messageHandlerName = "hearthPrime"

    @MainActor
    public static var userScript: WKUserScript {
        let source = """
        (function () {
          if (window.hearthPrimeHarvester) return;

          var HOSTS = [/primevideo\\.com/i, /amazon\\.com/i, /media-amazon\\.com/i];
          var PRIME_ORIGIN = 'https://www.primevideo.com';
          var lastDomPayload = '';

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

          function postAPI(body, url) {
            try {
              window.webkit.messageHandlers.\(messageHandlerName).postMessage({
                url: url,
                body: typeof body === 'string' ? body : JSON.stringify(body)
              });
            } catch (e) {}
          }

          function postDomCatalog(payload) {
            try {
              window.webkit.messageHandlers.\(messageHandlerName).postMessage({
                type: 'domCatalog',
                body: payload
              });
            } catch (e) {}
          }

          function resolveDetailHref(href) {
            if (!href) return null;
            try {
              var url = new URL(href, PRIME_ORIGIN);
              if (!/\\/detail\\//i.test(url.pathname)) return null;
              return url.href;
            } catch (e) {
              return null;
            }
          }

          function bestImageSrc(img) {
            if (!img) return null;
            var srcset = img.getAttribute('srcset');
            if (srcset) {
              var best = null;
              var bestWidth = -1;
              srcset.split(',').forEach(function (entry) {
                var parts = entry.trim().split(/\\s+/);
                if (!parts[0]) return;
                var width = 0;
                if (parts[1] && /w$/i.test(parts[1])) {
                  width = parseInt(parts[1], 10) || 0;
                }
                var src = parts[0];
                if (/SX899|_SX899_/i.test(src)) {
                  best = src;
                  bestWidth = 99999;
                  return;
                }
                if (/SX624|_SX624_/i.test(src) && bestWidth < 624) {
                  best = src;
                  bestWidth = 624;
                  return;
                }
                if (width > bestWidth) {
                  best = src;
                  bestWidth = width;
                }
              });
              if (best) return best;
            }
            return img.src || img.getAttribute('src') || null;
          }

          function cardTitle(article) {
            var attr = article.getAttribute('data-card-title');
            if (attr && attr.trim()) return attr.trim();
            var link = article.querySelector('a[href*="/detail/"]');
            if (link && link.textContent && link.textContent.trim()) return link.textContent.trim();
            return null;
          }

          function rowTitleForList(listEl, index) {
            var node = listEl;
            for (var depth = 0; depth < 8 && node; depth++) {
              var heading = node.querySelector(
                'h1, h2, h3, h4, [data-testid*="heading"], [data-testid*="title"], [class*="Heading"]'
              );
              if (heading && heading.textContent && heading.textContent.trim()) {
                var text = heading.textContent.trim();
                if (text.length < 80) return text;
              }
              var prev = node.previousElementSibling;
              while (prev) {
                if (/^H[1-4]$/i.test(prev.tagName) && prev.textContent && prev.textContent.trim()) {
                  return prev.textContent.trim();
                }
                prev = prev.previousElementSibling;
              }
              node = node.parentElement;
            }
            return index === 0 ? 'Browse' : 'Browse ' + (index + 1);
          }

          function scrapeCard(article) {
            var title = cardTitle(article);
            if (!title) return null;
            var link = article.querySelector('a[href*="/detail/"]');
            var detailURL = link ? resolveDetailHref(link.getAttribute('href')) : null;
            var img = article.querySelector('img[data-testid="base-image"]')
              || article.querySelector('img[src*="ssl-images-amazon"]')
              || article.querySelector('img[src*="pv-target-images"]')
              || article.querySelector('img');
            var posterURL = bestImageSrc(img);
            if (!detailURL && !posterURL) return null;
            return { title: title, detailURL: detailURL, posterURL: posterURL };
          }

          function scrapeDOM() {
            var lists = document.querySelectorAll('ul[data-testid="card-container-list"]');
            var rows = [];
            if (lists.length) {
              lists.forEach(function (list, index) {
                var tiles = [];
                list.querySelectorAll('article[data-testid="card"]').forEach(function (article) {
                  var tile = scrapeCard(article);
                  if (tile) tiles.push(tile);
                });
                if (tiles.length) {
                  rows.push({ title: rowTitleForList(list, index), tiles: tiles });
                }
              });
            } else {
              var tiles = [];
              document.querySelectorAll('article[data-testid="card"]').forEach(function (article) {
                var tile = scrapeCard(article);
                if (tile) tiles.push(tile);
              });
              if (tiles.length) {
                rows.push({ title: 'Browse', tiles: tiles });
              }
            }
            return { rows: rows };
          }

          function scrapeAndPostDom() {
            var data = scrapeDOM();
            if (!data.rows || !data.rows.length) return;
            var tileCount = data.rows.reduce(function (n, row) { return n + row.tiles.length; }, 0);
            if (tileCount < 1) return;
            var json = JSON.stringify(data);
            if (json === lastDomPayload) return;
            lastDomPayload = json;
            postDomCatalog(json);
          }

          var domScrapeTimer = null;
          function debouncedDomScrape() {
            if (domScrapeTimer) clearTimeout(domScrapeTimer);
            domScrapeTimer = setTimeout(scrapeAndPostDom, 300);
          }

          function startDomScraper() {
            scrapeAndPostDom();
            setTimeout(scrapeAndPostDom, 2000);
            setTimeout(scrapeAndPostDom, 5000);
            try {
              var observer = new MutationObserver(debouncedDomScrape);
              observer.observe(document.documentElement, { childList: true, subtree: true });
            } catch (e) {}
          }

          if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', startDomScraper, { once: true });
          } else {
            startDomScraper();
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
                    if (looksLikeJSON(text, ct)) postAPI(text, reqUrl);
                  });
                } catch (e) {}
              }
              return response;
            });
          };

          var origOpen = XMLHttpRequest.prototype.open;
          var origSend = XMLHttpRequest.prototype.send;
          XMLHttpRequest.prototype.open = function (method, url) {
            this._hearthPrimeUrl = url;
            return origOpen.apply(this, arguments);
          };
          XMLHttpRequest.prototype.send = function () {
            var xhr = this;
            xhr.addEventListener('load', function () {
              try {
                var ct = xhr.getResponseHeader ? xhr.getResponseHeader('content-type') : '';
                if (onHost(xhr._hearthPrimeUrl) && looksLikeJSON(xhr.responseText, ct)) {
                  postAPI(xhr.responseText, xhr._hearthPrimeUrl);
                }
              } catch (e) {}
            });
            return origSend.apply(this, arguments);
          };

          window.hearthPrimeHarvester = { ready: true, rescrape: scrapeAndPostDom };
        })();
        """
        return WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: false)
    }

    @MainActor
    public static func makeMessageHandler(
        onAPIPayload: @escaping @Sendable (String, String) -> Void,
        onDomCatalog: @escaping @Sendable (String) -> Void = { _ in }
    ) -> PrimeCatalogMessageHandler {
        PrimeCatalogMessageHandler(onAPIPayload: onAPIPayload, onDomCatalog: onDomCatalog)
    }
}

@MainActor
public final class PrimeCatalogMessageHandler: NSObject, WKScriptMessageHandler {
    public var onAPIPayload: @Sendable (String, String) -> Void
    public var onDomCatalog: @Sendable (String) -> Void

    public init(
        onAPIPayload: @escaping @Sendable (String, String) -> Void,
        onDomCatalog: @escaping @Sendable (String) -> Void = { _ in }
    ) {
        self.onAPIPayload = onAPIPayload
        self.onDomCatalog = onDomCatalog
    }

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == PrimeCatalogHarvester.messageHandlerName,
              let body = message.body as? [String: Any]
        else { return }

        if let type = body["type"] as? String, type == "domCatalog",
           let jsonString = body["body"] as? String {
            onDomCatalog(jsonString)
            return
        }

        guard let jsonString = body["body"] as? String,
              let sourceURL = body["url"] as? String
        else { return }
        onAPIPayload(jsonString, sourceURL)
    }
}
