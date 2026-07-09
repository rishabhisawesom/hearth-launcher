import AppKit
import SwiftUI
import CoreUI
import FeatureApplications
import FeatureStreaming

/// Mutable key-focus state shared with the NSEvent monitor.
private final class PrimeKeyContext {
    var webContentFocused = true
    var isPlaybackActive = false
    var nativeBrowseActive = false
    var onClose: (() -> Void)?
    var onExitPlayback: (() -> Void)?
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
}

struct PrimeExperienceView: View {
    let app: CuratedApp
    let onClose: () -> Void

    @Environment(\.hearthPalette) private var palette
    @State private var store = PrimeCatalogStore()
    @State private var harvestHandler = PrimeCatalogHarvester.makeMessageHandler(onAPIPayload: { _, _ in })
    @State private var playbackURL: URL?
    @State private var webContentFocused = true
    @State private var browseFocusSeed = 0
    @State private var forceWebShell = false
    @State private var keyContext = PrimeKeyContext()
    @State private var keyMonitor: Any?

    private var nativeBrowseActive: Bool { store.showsNativeBrowse && playbackURL == nil }
    private var backIsFocused: Bool { !webContentFocused && !nativeBrowseActive }
    private var harvestURL: URL? { InAppStreaming.url(for: app.id) }

    var body: some View {
        Group {
            if forceWebShell {
                StreamingShellView(app: app) {
                    forceWebShell = false
                }
            } else {
                experienceContent
            }
        }
        .background(palette.background)
        .onAppear {
            harvestHandler.onAPIPayload = { jsonString, sourceURL in
                Task { @MainActor in
                    store.ingest(jsonString: jsonString, sourceURL: sourceURL)
                }
            }
            harvestHandler.onDomCatalog = { jsonString in
                Task { @MainActor in
                    store.ingestDomCatalog(jsonString: jsonString)
                }
            }
            syncKeyContext()
            installKeyMonitor()
        }
        .onChange(of: playbackURL) { _, newValue in
            keyContext.isPlaybackActive = newValue != nil
            webContentFocused = newValue != nil || store.showsHarvestWebView
            if newValue == nil, store.showsNativeBrowse {
                browseFocusSeed += 1
            }
            syncKeyContext()
        }
        .onChange(of: store.phase) { _, _ in
            if nativeBrowseActive {
                webContentFocused = false
                browseFocusSeed += 1
            } else if store.showsHarvestWebView, playbackURL == nil {
                webContentFocused = true
            }
            syncKeyContext()
        }
        .onDisappear {
            removeKeyMonitor()
            NSApp.keyWindow?.makeFirstResponder(nil)
        }
    }

    @ViewBuilder
    private var experienceContent: some View {
        ZStack(alignment: .topLeading) {
            if let playbackURL {
                playbackOverlay(url: playbackURL)
            } else if store.showsNativeBrowse {
                nativeBrowseContent
            }

            if playbackURL == nil, store.showsHarvestWebView, let harvestURL {
                StreamingWebView(
                    url: harvestURL,
                    isContentFocused: webContentFocused,
                    additionalUserScripts: [PrimeCatalogHarvester.userScript],
                    scriptMessageHandlers: [(PrimeCatalogHarvester.messageHandlerName, harvestHandler)],
                    onLoadFinished: { store.webViewDidFinishLoad() }
                )
                .allowsHitTesting(webContentFocused)
                .ignoresSafeArea()
            }

            if playbackURL == nil, !store.showsNativeBrowse {
                harvestStatusBanner
            }

            backButton
                .padding(HearthSpacing.screenPadding)
        }
    }

    @ViewBuilder
    private var nativeBrowseContent: some View {
        VStack(spacing: 0) {
            if store.phase == .empty {
                emptyBanner
            }
            PrimeBrowseView(catalog: store.catalog, focusSeed: browseFocusSeed) { tile in
                if let detailURL = tile.detailURL {
                    playbackURL = detailURL
                    webContentFocused = true
                }
            }
        }
    }

    @ViewBuilder
    private var harvestStatusBanner: some View {
        VStack(alignment: .leading, spacing: HearthSpacing.grid) {
            Text("Prime Video")
                .font(HearthTypography.title)
                .foregroundStyle(palette.textPrimary)

            Text(statusMessage)
                .font(HearthTypography.body)
                .foregroundStyle(palette.textSecondary)

            if store.phase == .needsLogin {
                Text("Sign in below. Catalog rows appear automatically after Prime loads.")
                    .font(HearthTypography.body)
                    .foregroundStyle(palette.textSecondary)
            } else if store.phase == .loading, store.responseCount > 0 {
                Text("Captured \(store.responseCount) responses — extracting rows…")
                    .font(HearthTypography.body)
                    .foregroundStyle(palette.textSecondary)
            }
        }
        .padding(HearthSpacing.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var emptyBanner: some View {
        HStack(spacing: HearthSpacing.section) {
            Text("Catalog empty — browse in web")
                .font(HearthTypography.body)
                .foregroundStyle(palette.textSecondary)

            Button("Open web browse") {
                forceWebShell = true
            }
            .buttonStyle(.plain)
            .font(HearthTypography.body)
            .foregroundStyle(palette.accent)
        }
        .padding(.horizontal, HearthSpacing.screenPadding)
        .padding(.vertical, HearthSpacing.grid)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.surface.opacity(0.95))
    }

    @ViewBuilder
    private func playbackOverlay(url: URL) -> some View {
        StreamingWebView(
            url: url,
            leanbackEnabled: false,
            isContentFocused: webContentFocused
        )
        .allowsHitTesting(webContentFocused)
        .ignoresSafeArea()
    }

    private var statusMessage: String {
        switch store.phase {
        case .loading:
            store.responseCount > 0 ? "Parsing catalog…" : "Loading Prime…"
        case .needsLogin:
            "Sign in to Prime Video"
        case .ready:
            "Loading browse…"
        case .empty:
            "Using demo rows"
        }
    }

    private var backButton: some View {
        Button(action: {
            if playbackURL != nil {
                playbackURL = nil
            } else {
                onClose()
            }
        }) {
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
        .focusable(backIsFocused)
        .animation(.easeOut(duration: 0.15), value: backIsFocused)
    }

    private func syncKeyContext() {
        keyContext.webContentFocused = webContentFocused
        keyContext.isPlaybackActive = playbackURL != nil
        keyContext.nativeBrowseActive = nativeBrowseActive
        keyContext.onClose = onClose
        keyContext.onExitPlayback = { playbackURL = nil }
        keyContext.setWebContentFocused = { webContentFocused = $0 }
    }

    private func installKeyMonitor() {
        let context = keyContext
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // nativeBrowse: arrows/Return/Esc go to PrimeBrowseView (.onKeyPress)
            if context.nativeBrowseActive {
                return event
            }

            switch event.keyCode {
            case 53: // Escape — harvestBack: exit app; playbackWeb: focus back; playbackBack: exit playback
                if context.webContentFocused, context.isPlaybackActive {
                    context.focusBack()
                    return nil
                }
                if context.isPlaybackActive {
                    context.onExitPlayback?()
                    return nil
                }
                context.onClose?()
                return nil
            case 51: // Delete / Backspace
                if context.webContentFocused, context.isPlaybackActive {
                    context.focusBack()
                    return nil
                }
                return event
            case 36: // Return — harvestWeb: pass; harvestBack/playbackBack: chrome action
                guard !context.webContentFocused else { return event }
                if context.isPlaybackActive {
                    context.onExitPlayback?()
                } else {
                    context.onClose?()
                }
                return nil
            case 123, 124, 125, 126: // Arrow keys — harvestWeb/playbackWeb: pass; playbackBack down: focus web
                guard !context.webContentFocused else { return event }
                if event.keyCode == 125, context.isPlaybackActive {
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
