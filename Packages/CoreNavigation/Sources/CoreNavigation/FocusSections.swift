public enum FocusSections {
    public static func moved(
        section: Int,
        tile: Int,
        itemCounts: [Int],
        direction: FocusDirection
    ) -> (section: Int, tile: Int) {
        guard !itemCounts.isEmpty else { return (0, 0) }

        let s = min(max(section, 0), itemCounts.count - 1)
        let count = itemCounts[s]
        guard count > 0 else { return (s, 0) }
        let t = min(max(tile, 0), count - 1)

        switch direction {
        case .left:
            if t > 0 { return (s, t - 1) }
        case .right:
            if t < count - 1 { return (s, t + 1) }
        case .up:
            if s > 0 {
                let prevCount = itemCounts[s - 1]
                guard prevCount > 0 else { return (s, t) }
                return (s - 1, min(t, prevCount - 1))
            }
        case .down:
            if s < itemCounts.count - 1 {
                let nextCount = itemCounts[s + 1]
                guard nextCount > 0 else { return (s, t) }
                return (s + 1, min(t, nextCount - 1))
            }
        }

        return (s, t)
    }
}
