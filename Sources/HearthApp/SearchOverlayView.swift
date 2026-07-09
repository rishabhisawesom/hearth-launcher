import SwiftUI
import CoreUI
import FeatureApplications

struct SearchOverlayView: View {
    @Binding var isPresented: Bool
    let onLaunch: (CuratedApp) -> Void

    @Environment(\.hearthPalette) private var palette
    @State private var query = ""
    @State private var focusedIndex = 0
    @FocusState private var fieldFocused: Bool

    private var results: [SearchResult] {
        SearchIndex.search(query)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(alignment: .leading, spacing: HearthSpacing.grid) {
                TextField("Search apps…", text: $query)
                    .textFieldStyle(.plain)
                    .font(HearthTypography.body)
                    .foregroundStyle(palette.textPrimary)
                    .padding()
                    .background(palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: HearthRadius.tile))
                    .focused($fieldFocused)

                if !results.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Apps")
                            .font(HearthTypography.caption)
                            .foregroundStyle(palette.textSecondary)

                        ForEach(results.indices, id: \.self) { index in
                            resultRow(results[index], isFocused: index == focusedIndex)
                        }
                    }
                } else if !query.isEmpty {
                    Text("No results")
                        .font(HearthTypography.caption)
                        .foregroundStyle(palette.textSecondary)
                }
            }
            .padding(HearthSpacing.screenPadding)
            .frame(maxWidth: 640)
            .background(palette.background.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: HearthRadius.tile))
            .shadow(radius: 24)
        }
        .focusable()
        .onAppear {
            query = ""
            focusedIndex = 0
            fieldFocused = true
        }
        .onChange(of: query) { _, _ in
            focusedIndex = 0
        }
        .onKeyPress(.escape) { dismiss(); return .handled }
        .onKeyPress(.upArrow) { moveSelection(-1); return .handled }
        .onKeyPress(.downArrow) { moveSelection(1); return .handled }
        .onKeyPress(.return) { activateFocused(); return .handled }
    }

    private func resultRow(_ result: SearchResult, isFocused: Bool) -> some View {
        Text(result.title)
            .font(HearthTypography.body)
            .foregroundStyle(palette.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isFocused ? palette.accent.opacity(0.25) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func moveSelection(_ delta: Int) {
        guard !results.isEmpty else { return }
        focusedIndex = max(0, min(results.count - 1, focusedIndex + delta))
    }

    private func activateFocused() {
        guard results.indices.contains(focusedIndex) else { return }
        onLaunch(results[focusedIndex].app)
        dismiss()
    }

    private func dismiss() {
        isPresented = false
    }
}
