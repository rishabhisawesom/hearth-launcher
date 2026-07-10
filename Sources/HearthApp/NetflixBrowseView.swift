import SwiftUI
import CoreUI
import CoreNavigation
import FeatureStreaming

struct NetflixBrowseView: View {
    let catalog: NetflixCatalog
    var focusSeed: Int = 0
    let onTileActivate: (NetflixTile) -> Void

    @Environment(\.hearthPalette) private var palette
    @FocusState private var gridFocused: Bool
    @State private var focusedRowIndex = 0
    @State private var focusedTileIndex = 0

    private let tileWidth: CGFloat = 200
    private let tileHeight: CGFloat = 300

    var body: some View {
        GeometryReader { proxy in
            let pad = HearthSpacing.screenPadding
            ScrollViewReader { scrollProxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: HearthSpacing.section) {
                        Text("Netflix")
                            .font(HearthTypography.title)
                            .foregroundStyle(palette.textPrimary)

                        ForEach(catalog.rows.indices, id: \.self) { rowIndex in
                            rowSection(rowIndex: rowIndex)
                                .id(rowIndex)
                        }
                    }
                    .padding(pad)
                    .frame(width: proxy.size.width, alignment: .topLeading)
                }
                .onChange(of: focusedRowIndex) { _, newValue in
                    withAnimation(.easeOut(duration: 0.2)) {
                        scrollProxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
        }
        .focusable()
        .focused($gridFocused)
        .onAppear {
            // ponytail: defer until harvest WKWebView relinquishes AppKit first responder
            DispatchQueue.main.async { gridFocused = true }
        }
        .onChange(of: focusSeed) { _, _ in
            DispatchQueue.main.async { gridFocused = true }
        }
        .onKeyPress(.leftArrow) { move(.left); return .handled }
        .onKeyPress(.rightArrow) { move(.right); return .handled }
        .onKeyPress(.upArrow) { move(.up); return .handled }
        .onKeyPress(.downArrow) { move(.down); return .handled }
        .onKeyPress(.return) { activateFocused(); return .handled }
    }

    @ViewBuilder
    private func rowSection(rowIndex: Int) -> some View {
        let row = catalog.rows[rowIndex]
        VStack(alignment: .leading, spacing: HearthSpacing.grid) {
            Text(row.title)
                .font(HearthTypography.body)
                .foregroundStyle(palette.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: HearthSpacing.grid) {
                    ForEach(row.tiles.indices, id: \.self) { tileIndex in
                        NetflixTileView(
                            tile: row.tiles[tileIndex],
                            isFocused: rowIndex == focusedRowIndex && tileIndex == focusedTileIndex
                        )
                        .frame(width: tileWidth, height: tileHeight)
                        .padding(HearthSpacing.focusOverflow)
                    }
                }
            }
        }
    }

    private func move(_ direction: FocusDirection) {
        guard catalog.rows.indices.contains(focusedRowIndex) else { return }
        let tileCount = catalog.rows[focusedRowIndex].tiles.count
        guard tileCount > 0 else { return }

        switch direction {
        case .left:
            if focusedTileIndex > 0 {
                focusedTileIndex -= 1
            }
        case .right:
            if focusedTileIndex < tileCount - 1 {
                focusedTileIndex += 1
            }
        case .up:
            if focusedRowIndex > 0 {
                focusedRowIndex -= 1
                focusedTileIndex = min(focusedTileIndex, catalog.rows[focusedRowIndex].tiles.count - 1)
            }
        case .down:
            if focusedRowIndex < catalog.rows.count - 1 {
                focusedRowIndex += 1
                focusedTileIndex = min(focusedTileIndex, catalog.rows[focusedRowIndex].tiles.count - 1)
            }
        }
    }

    private func activateFocused() {
        guard catalog.rows.indices.contains(focusedRowIndex) else { return }
        let row = catalog.rows[focusedRowIndex]
        guard row.tiles.indices.contains(focusedTileIndex) else { return }
        onTileActivate(row.tiles[focusedTileIndex])
    }
}

private struct NetflixTileView: View {
    @Environment(\.hearthPalette) private var palette

    let tile: NetflixTile
    let isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: HearthSpacing.grid) {
            poster
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Text(tile.title)
                .font(HearthTypography.body)
                .foregroundStyle(palette.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .padding(HearthSpacing.grid)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: HearthRadius.tile))
        .overlay {
            RoundedRectangle(cornerRadius: HearthRadius.tile)
                .strokeBorder(isFocused ? palette.accent : .clear, lineWidth: 4)
        }
        .animation(.easeOut(duration: 0.15), value: isFocused)
    }

    @ViewBuilder
    private var poster: some View {
        PosterImageView(
            service: .netflix,
            tileID: tile.id,
            title: tile.title,
            posterURL: tile.posterURL,
            localPosterName: tile.localPosterName,
            cornerRadius: HearthRadius.tile
        )
    }
}
