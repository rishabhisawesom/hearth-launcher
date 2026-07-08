public enum FocusGrid {
    public static func moved(
        from index: Int,
        columns: Int,
        itemCount: Int,
        direction: FocusDirection
    ) -> Int {
        guard itemCount > 0, columns > 0, index >= 0, index < itemCount else { return 0 }

        let col = index % columns

        switch direction {
        case .left:
            if col > 0 { return index - 1 }
        case .right:
            if col < columns - 1, index + 1 < itemCount { return index + 1 }
        case .up:
            if index >= columns { return index - columns }
        case .down:
            let next = index + columns
            if next < itemCount { return next }
        }

        return index
    }
}
