import XCTest
@testable import FeatureApplications

final class SectionLayoutPreferencesTests: XCTestCase {
    func testFilterAndOrderHidesAndSorts() {
        let sections = [
            HomeSection(id: "streaming", title: "Streaming", tiles: []),
            HomeSection(id: "favorites", title: "Favorites", tiles: []),
            HomeSection(id: "recents", title: "Recently Opened", tiles: []),
        ]

        SectionLayoutPreferences.order = ["recents", "streaming", "favorites"]
        SectionLayoutPreferences.setVisible("favorites", false)

        let result = SectionLayoutPreferences.filterAndOrder(sections)
        XCTAssertEqual(result.map(\.id), ["recents", "streaming"])

        SectionLayoutPreferences.setVisible("favorites", true)
        SectionLayoutPreferences.order = SectionLayoutPreferences.defaultOrder
    }
}
