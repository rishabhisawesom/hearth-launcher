import SwiftUI
import CoreUI
import CoreNavigation
import FeatureApplications

struct HomeView: View {
    private let sections: [HomeSection]
    private let tileWidth: CGFloat = 220

    @State private var focusedSection = 0
    @State private var focusedTile = 0

    init(provider: any HomeSectionProvider = StreamingSectionProvider()) {
        self.sections = provider.sections
    }

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
        _ = AppLauncher.launch(app)
    }
}

private struct TileView: View {
    let title: String
    let isFocused: Bool

    var body: some View {
        Text(title)
            .font(HearthTypography.body)
            .foregroundStyle(HearthColors.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 120)
            .background(HearthColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HearthRadius.tile))
            .overlay {
                RoundedRectangle(cornerRadius: HearthRadius.tile)
                    .strokeBorder(isFocused ? HearthColors.accent : .clear, lineWidth: 4)
            }
            .animation(.easeOut(duration: 0.15), value: isFocused)
    }
}
