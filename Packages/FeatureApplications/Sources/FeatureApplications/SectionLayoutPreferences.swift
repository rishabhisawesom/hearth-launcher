import Foundation

public enum SectionLayoutPreferences {
    public static let defaultOrder = ["favorites", "recents", "streaming"]

    private static let orderKey = "homeSectionOrder"
    private static let hiddenKey = "homeSectionHidden"

    public static var order: [String] {
        get {
            let saved = UserDefaults.standard.stringArray(forKey: orderKey) ?? defaultOrder
            return saved.filter { defaultOrder.contains($0) }
                + defaultOrder.filter { !saved.contains($0) }
        }
        set {
            UserDefaults.standard.set(newValue.filter { defaultOrder.contains($0) }, forKey: orderKey)
        }
    }

    public static func isVisible(_ sectionId: String) -> Bool {
        !hiddenIDs().contains(sectionId)
    }

    public static func setVisible(_ sectionId: String, _ visible: Bool) {
        var hidden = hiddenIDs()
        if visible {
            hidden.remove(sectionId)
        } else {
            hidden.insert(sectionId)
        }
        UserDefaults.standard.set(Array(hidden), forKey: hiddenKey)
    }

    public static func filterAndOrder(_ sections: [HomeSection]) -> [HomeSection] {
        let hidden = hiddenIDs()
        return order.compactMap { id in
            guard !hidden.contains(id) else { return nil }
            return sections.first { $0.id == id }
        }
    }

    public static func title(for sectionId: String) -> String {
        switch sectionId {
        case "favorites": "Favorites"
        case "recents": "Recently Opened"
        case "streaming": "Streaming"
        default: sectionId
        }
    }

    private static func hiddenIDs() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: hiddenKey) ?? [])
    }
}
