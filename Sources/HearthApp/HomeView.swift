import SwiftUI
import CoreUI
import CoreNavigation

struct HomeView: View {
    private let columns = 4
    private let tiles = [
        "Netflix", "Spotify", "Safari", "Photos",
        "Music", "Settings", "YouTube", "Plex",
        "Games", "News", "Weather", "Files",
    ]

    @State private var focusedIndex = 0

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: HearthSpacing.grid), count: columns)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: HearthSpacing.section) {
            Text("Hearth")
                .font(HearthTypography.title)
                .foregroundStyle(HearthColors.textPrimary)

            LazyVGrid(columns: gridColumns, spacing: HearthSpacing.grid) {
                ForEach(tiles.indices, id: \.self) { index in
                    TileView(title: tiles[index], isFocused: index == focusedIndex)
                }
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
    }

    private func move(_ direction: FocusDirection) {
        focusedIndex = FocusGrid.moved(
            from: focusedIndex,
            columns: columns,
            itemCount: tiles.count,
            direction: direction
        )
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
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .animation(.easeOut(duration: 0.15), value: isFocused)
    }
}
