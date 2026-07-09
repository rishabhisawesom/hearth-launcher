import AppKit
import SwiftUI
import CoreUI
import CoreNavigation
import FeatureApplications

struct HomeView: View {
    private let tileWidth: CGFloat = 220

    @State private var sections: [HomeSection] = []
    @State private var focusedSection = 0
    @State private var focusedTile = 0

    var body: some View {
        VStack(alignment: .leading, spacing: HearthSpacing.section) {
            Text("Hearth")
                .font(HearthTypography.title)
                .foregroundStyle(HearthColors.textPrimary)

            ForEach(sections.indices, id: \.self) { sectionIndex in
                sectionView(sections[sectionIndex], sectionIndex: sectionIndex)
            }
        }
        .padding(HearthSpacing.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(HearthColors.background)
        .focusable()
        .onAppear { reloadSections() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            reloadSections()
        }
        .onKeyPress(.leftArrow) { move(.left); return .handled }
        .onKeyPress(.rightArrow) { move(.right); return .handled }
        .onKeyPress(.upArrow) { move(.up); return .handled }
        .onKeyPress(.downArrow) { move(.down); return .handled }
        .onKeyPress(.return) { launchFocused(); return .handled }
    }

    @ViewBuilder
    private func sectionView(_ section: HomeSection, sectionIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: HearthSpacing.grid) {
            Text(section.title)
                .font(HearthTypography.body)
                .foregroundStyle(HearthColors.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: HearthSpacing.grid) {
                    ForEach(section.tiles.indices, id: \.self) { tileIndex in
                        TileView(
                            title: section.tiles[tileIndex].title,
                            app: section.tiles[tileIndex].app,
                            isFocused: sectionIndex == focusedSection && tileIndex == focusedTile
                        )
                        .frame(width: tileWidth)
                        .padding(HearthSpacing.focusOverflow)
                        .id(tileIndex)
                    }
                }
                .padding(.horizontal, HearthSpacing.focusOverflow)
            }
        }
    }

    private func reloadSections() {
        sections = HomeSectionsBuilder.build()
        focusedSection = min(focusedSection, max(sections.count - 1, 0))
        let tileCount = sections.indices.contains(focusedSection) ? sections[focusedSection].tiles.count : 0
        focusedTile = min(focusedTile, max(tileCount - 1, 0))
    }

    private func move(_ direction: FocusDirection) {
        let itemCounts = sections.map(\.tiles.count)
        let next = FocusSections.moved(
            section: focusedSection,
            tile: focusedTile,
            itemCounts: itemCounts,
            direction: direction
        )
        focusedSection = next.section
        focusedTile = next.tile
    }

    @MainActor
    private func launchFocused() {
        guard sections.indices.contains(focusedSection) else { return }
        let tiles = sections[focusedSection].tiles
        guard tiles.indices.contains(focusedTile), let app = tiles[focusedTile].app else { return }
        if AppLauncher.launch(app) {
            reloadSections()
        }
    }
}

private struct TileView: View {
    let title: String
    let app: CuratedApp?
    let isFocused: Bool

    private let iconDisplaySize: CGFloat = 64

    var body: some View {
        VStack(spacing: HearthSpacing.grid / 2) {
            tileIcon
            Text(title)
                .font(HearthTypography.body)
                .foregroundStyle(HearthColors.textPrimary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .padding(.vertical, HearthSpacing.grid / 2)
        .background(HearthColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HearthRadius.tile))
        .overlay {
            RoundedRectangle(cornerRadius: HearthRadius.tile)
                .strokeBorder(isFocused ? HearthColors.accent : .clear, lineWidth: 4)
        }
        .animation(.easeOut(duration: 0.15), value: isFocused)
    }

    @ViewBuilder
    private var tileIcon: some View {
        if let app, let nsImage = AppIconProvider.icon(for: app) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: iconDisplaySize, height: iconDisplaySize)
        } else {
            Image(systemName: AppIconProvider.fallbackSymbolName)
                .font(.system(size: iconDisplaySize * 0.6))
                .foregroundStyle(HearthColors.textSecondary)
                .frame(width: iconDisplaySize, height: iconDisplaySize)
        }
    }
}
