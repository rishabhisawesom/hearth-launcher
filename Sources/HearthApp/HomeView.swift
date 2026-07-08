import SwiftUI
import CoreUI
import CoreNavigation
import FeatureApplications

struct HomeView: View {
    private let columns = 4
    private let apps = CuratedApps.streaming

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
                ForEach(apps.indices, id: \.self) { index in
                    TileView(title: apps[index].name, isFocused: index == focusedIndex)
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
