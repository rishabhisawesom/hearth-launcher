import WebKit

/// Injects heuristic spatial D-pad navigation into desktop streaming sites.
enum LeanbackNavigation {
    // ponytail: heuristic polyfill — not a real TV leanback app; breaks when site DOM/classes change
    private static let scriptSource = """
    (function () {
      if (window.hearthLeanback) return;

      var PROFILE = '__HEARTH_PROFILE__';
      var FOCUS = 'hearth-leanback-focus';
      var style = document.createElement('style');
      style.textContent = '.' + FOCUS + '{outline:3px solid #ff6b00!important;outline-offset:4px!important;position:relative;z-index:9999!important}';
      (document.head || document.documentElement).appendChild(style);

      var focused = null;
      var lastPath = location.pathname;
      var initTimer = null;

      function visible(el) {
        var r = el.getBoundingClientRect();
        if (r.width < 4 || r.height < 4) return false;
        var s = getComputedStyle(el);
        if (s.display === 'none' || s.visibility === 'hidden' || s.opacity === '0') return false;
        var p = el.parentElement;
        while (p && p !== document.body) {
          var ps = getComputedStyle(p);
          if (ps.display === 'none' || ps.visibility === 'hidden' || ps.opacity === '0') return false;
          p = p.parentElement;
        }
        return true;
      }

      function dedupeNested(list) {
        return list.filter(function (el) {
          for (var i = 0; i < list.length; i++) {
            if (list[i] !== el && list[i].contains(el)) return false;
          }
          return true;
        });
      }

      function queryGeneric() {
        return Array.prototype.slice.call(
          document.querySelectorAll(
            'a[href],button:not([disabled]),[role="button"]:not([aria-disabled="true"]),[role="link"],input:not([disabled]),select,textarea,[tabindex]:not([tabindex="-1"])'
          )
        );
      }

      function primeResolve(el) {
        if (!el) return null;
        if (el.matches('a[href],button:not([disabled]),[role="button"]:not([aria-disabled="true"]),[role="link"]')) return el;
        var inner = el.querySelector('a[href],button:not([disabled]),[role="button"]:not([aria-disabled="true"]),[role="link"]');
        return inner || el;
      }

      function primeIsChrome(el) {
        var node = el;
        while (node && node !== document.body) {
          var tid = node.getAttribute && node.getAttribute('data-testid');
          if (tid) {
            if (tid === 'see-more' || tid === 'pv-navigation-bar' || tid.indexOf('pagination') !== -1) return true;
            if (tid.indexOf('pv-nav-') === 0 || tid.indexOf('nav-') === 0) return true;
            if (tid === 'card' || tid === 'carousel-item' || tid === 'title-card' || tid === 'card-overlay' || tid.indexOf('title-card') !== -1 || tid.indexOf('packshot') !== -1) return false;
          }
          if (node.getAttribute && node.getAttribute('data-card-title')) return false;
          node = node.parentElement;
        }
        if (el.closest && el.closest('section[data-testid="card-section"]')) return false;
        var r = el.getBoundingClientRect();
        // ponytail: size heuristic — chrome buttons are tiny; posters are ~120px+
        return r.width < 48 || r.height < 48;
      }

      function primeIsContent(el) {
        var node = el;
        while (node && node !== document.body) {
          var tid = node.getAttribute && node.getAttribute('data-testid');
          if (tid === 'card' || tid === 'carousel-item' || tid === 'title-card' || tid === 'card-overlay' || tid.indexOf('title-card') !== -1 || tid.indexOf('packshot') !== -1) return true;
          if (node.getAttribute && node.getAttribute('data-card-title')) return true;
          node = node.parentElement;
        }
        if (el.closest && el.closest('section[data-testid="card-section"]')) return true;
        return false;
      }

      function queryPrimeContent() {
        var out = [];
        var seen = new Set();
        function add(el) {
          var target = primeResolve(el);
          if (!target || seen.has(target)) return;
          seen.add(target);
          out.push(target);
        }
        var selectors = [
          '[data-testid="card"]',
          '[data-testid="card-overlay"]',
          '[data-testid="carousel-item"]',
          '[data-testid="title-card"]',
          '[data-testid*="title-card"]',
          '[data-testid*="packshot"]',
          '[data-card-title]',
          'section[data-testid="card-section"] button[aria-label]',
          'a[href*="/gp/video/detail/"]',
          'a[href*="/detail/"]',
          '[class*="TitleCard"]',
          '[class*="Packshot"]'
        ];
        selectors.forEach(function (sel) {
          document.querySelectorAll(sel).forEach(add);
        });
        return out;
      }

      function queryPrimeChrome() {
        var out = [];
        var seen = new Set();
        function add(el) {
          if (!el || seen.has(el)) return;
          seen.add(el);
          out.push(el);
        }
        document.querySelectorAll(
          'a[data-testid^="pv-nav-"],[data-testid="play-button"],[data-testid="see-more"],[data-testid="details-tab"],[data-testid="pv-navigation-bar"] a[href],button[data-testid]:not([disabled])'
        ).forEach(add);
        return out;
      }

      function mergePrimeLists() {
        var out = [];
        var seen = new Set();
        function add(el) {
          if (!el || seen.has(el)) return;
          seen.add(el);
          out.push(el);
        }
        queryPrimeContent().forEach(add);
        queryPrimeChrome().forEach(add);
        return out;
      }

      function visibleFocusables(list) {
        return dedupeNested(list).filter(visible);
      }

      function focusables() {
        if (PROFILE !== 'prime-video') return visibleFocusables(queryGeneric());
        // ponytail: tiered fallback — content-only query can match hidden SPA placeholders
        var tiers = [queryPrimeContent(), mergePrimeLists(), queryPrimeChrome(), queryGeneric()];
        for (var i = 0; i < tiers.length; i++) {
          var list = visibleFocusables(tiers[i]);
          if (list.length) return list;
        }
        return [];
      }

      function primeScoreAdjust(el) {
        if (PROFILE !== 'prime-video') return 0;
        if (primeIsContent(el)) {
          var r = el.getBoundingClientRect();
          return -Math.min(r.width, r.height) * 0.4;
        }
        if (primeIsChrome(el)) return 800;
        return 200;
      }

      function pickInitialFocus(list) {
        if (!list.length) return null;
        if (PROFILE !== 'prime-video') return list[0];
        var content = list.filter(primeIsContent);
        var pool = content.length ? content : list.filter(function (el) { return !primeIsChrome(el); });
        if (!pool.length) pool = list;
        pool.sort(function (a, b) {
          var ra = a.getBoundingClientRect();
          var rb = b.getBoundingClientRect();
          var dy = ra.top - rb.top;
          if (Math.abs(dy) > 24) return dy;
          return ra.left - rb.left;
        });
        return pool[0];
      }

      function setFocus(el) {
        if (focused) focused.classList.remove(FOCUS);
        focused = el || null;
        if (focused) {
          focused.classList.add(FOCUS);
          focused.scrollIntoView({ block: 'nearest', inline: 'nearest', behavior: 'smooth' });
        }
      }

      function center(el) {
        var r = el.getBoundingClientRect();
        return { x: r.left + r.width / 2, y: r.top + r.height / 2 };
      }

      function move(dir) {
        var list = focusables();
        if (!list.length) return;
        if (!focused || !document.body.contains(focused) || !visible(focused)) {
          setFocus(pickInitialFocus(list));
          return;
        }
        var fc = center(focused);
        var best = null;
        var bestScore = Infinity;
        for (var i = 0; i < list.length; i++) {
          var el = list[i];
          if (el === focused) continue;
          var c = center(el);
          var dx = c.x - fc.x;
          var dy = c.y - fc.y;
          if (dir === 'up' && dy >= -8) continue;
          if (dir === 'down' && dy <= 8) continue;
          if (dir === 'left' && dx >= -8) continue;
          if (dir === 'right' && dx <= 8) continue;
          var score;
          if (dir === 'left' || dir === 'right') {
            // ponytail: row band heuristic — misses staggered grids; tune ROW_BAND if carousels drift
            var rowBand = PROFILE === 'prime-video' ? 55 : 45;
            var rowPenalty = Math.abs(dy) > rowBand ? Math.abs(dy) * 12 : Math.abs(dy) * 2;
            score = Math.abs(dx) + rowPenalty + primeScoreAdjust(el);
          } else {
            var colPenalty = Math.abs(dx) > 120 ? Math.abs(dx) * 2 : Math.abs(dx) * 0.35;
            score = Math.abs(dy) + colPenalty + primeScoreAdjust(el);
          }
          if (score < bestScore) {
            bestScore = score;
            best = el;
          }
        }
        if (best) setFocus(best);
      }

      function activate() {
        if (!focused) {
          var list = focusables();
          if (list.length) setFocus(pickInitialFocus(list));
        }
        if (focused) focused.click();
      }

      function init() {
        if (!focused || !document.body.contains(focused) || !visible(focused)) {
          var list = focusables();
          if (list.length) setFocus(pickInitialFocus(list));
        }
      }

      window.hearthLeanback = {
        move: move,
        activate: activate,
        init: init,
        profile: PROFILE,
        ready: true,
        selfCheck: function () {
          return typeof move === 'function' && typeof activate === 'function' && document.documentElement !== null;
        }
      };
      document.documentElement.setAttribute('data-hearth-leanback', 'ready');

      // ponytail: DOM keydown backup — WKWebView often never delivers arrows to the page
      document.addEventListener('keydown', function (e) {
        var map = { ArrowUp: 'up', ArrowDown: 'down', ArrowLeft: 'left', ArrowRight: 'right' };
        if (map[e.key]) {
          if (!focusables().length) return;
          e.preventDefault();
          e.stopPropagation();
          move(map[e.key]);
          return;
        }
        if ((e.key === 'Enter' || e.key === ' ') && focused) {
          e.preventDefault();
          activate();
        }
      }, true);

      function scheduleInit() {
        clearTimeout(initTimer);
        initTimer = setTimeout(function () {
          if (location.pathname !== lastPath) {
            lastPath = location.pathname;
            focused = null;
          }
          init();
        }, 250);
      }

      var _push = history.pushState;
      var _replace = history.replaceState;
      history.pushState = function () { _push.apply(history, arguments); scheduleInit(); };
      history.replaceState = function () { _replace.apply(history, arguments); scheduleInit(); };
      window.addEventListener('popstate', scheduleInit);

      new MutationObserver(scheduleInit).observe(document.documentElement, { childList: true, subtree: true });

      function boot() {
        init();
        scheduleInit();
      }
      if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', boot);
      } else {
        boot();
      }
      window.addEventListener('load', scheduleInit);
      // ponytail: Prime SPA hydrates late — retry init until tiles appear
      [500, 1500, 3000, 5000].forEach(function (ms) { setTimeout(init, ms); });
    })();
    """

    /// JS snippet native code uses to nudge leanback after navigation.
    static let initScript = "window.hearthLeanback && hearthLeanback.init()"

    @MainActor
    static func userScript(for appId: String? = nil) -> WKUserScript {
        let profile: String = switch appId {
        case "prime-video": "prime-video"
        case "netflix": "netflix"
        default: "generic"
        }
        let source = scriptSource.replacingOccurrences(of: "__HEARTH_PROFILE__", with: profile)
        return WKUserScript(
            source: source,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
    }
}
