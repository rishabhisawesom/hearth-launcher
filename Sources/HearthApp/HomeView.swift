import SwiftUI
import CoreUI
import CoreNavigation
import FeatureApplications

struct HomeView: View {
    private let apps = CuratedApps.streaming
    private let columns = 2

    @State private var focusedIndex = 0

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: HearthSpacing.grid), count: columns)
    }

    var body: some View {
        GeometryReader { proxy in
            let pad = HearthSpacing.screenPadding
            let gap = HearthSpacing.grid
            let headerHeight: CGFloat = 72
            let gridHeight = proxy.size.height - pad * 2 - headerHeight - HearthSpacing.section
            let tileWidth = (proxy.size.width - pad * 2 - gap) / CGFloat(columns)
            let tileHeight = (gridHeight - gap) / CGFloat(columns)

            VStack(alignment: .leading, spacing: HearthSpacing.section) {
                Text("Hearth")
                    .font(HearthTypography.title)
                    .foregroundStyle(HearthColors.textPrimary)

                LazyVGrid(columns: gridColumns, spacing: gap) {
                    ForEach(apps.indices, id: \.self) { index in
                        TileView(
                            title: apps[index].name,
                            app: apps[index],
                            isFocused: index == focusedIndex
                        )
                        .frame(width: tileWidth, height: tileHeight)
                        .padding(HearthSpacing.focusOverflow)
                    }
                }
            }
            .padding(pad)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
        }
        .background(HearthColors.background)
        .focusable()
        .onKeyPress(.leftArrow) { move(.left); return .handled }
        .onKeyPress(.rightArrow) { move(.right); return .handled }
        .onKeyPress(.upArrow) { move(.up); return .handled }
        .onKeyPress(.downArrow) { move(.down); return .handled }
        .onKeyPress(.return) { launchFocused(); return .handled }
    }

    private func move(_ direction: FocusDirection) {
        focusedIndex = FocusGrid.moved(
            from: focusedIndex,
            columns: columns,
            itemCount: apps.count,
            direction: direction
        )
    }

    @MainActor
    private func launchFocused() {
        guard apps.indices.contains(focusedIndex) else { return }
        _ = AppLauncher.launch(apps[focusedIndex])
    }
}

private struct TileView: View {
    let title: String
    let app: CuratedApp
    let isFocused: Bool

    var body: some View {
        VStack(spacing: HearthSpacing.grid) {
            tileIcon
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Text(title)
                .font(HearthTypography.title)
                .foregroundStyle(HearthColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(HearthSpacing.grid)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        if let nsImage = AppIconProvider.icon(for: app) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(HearthSpacing.grid)
        } else {
            Image(systemName: AppIconProvider.fallbackSymbolName)
                .font(.system(size: 72))
                .foregroundStyle(HearthColors.textSecondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
