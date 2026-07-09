import XCTest
@testable import FeatureApplications

@MainActor
final class AppActivityStoreTests: XCTestCase {
    func testFavoritesAndRecents() {
        let store = AppActivityStore(inMemory: true)

        store.pinFavorite(appId: "netflix")
        store.pinFavorite(appId: "youtube")
        XCTAssertEqual(store.favoriteAppIds(), ["netflix", "youtube"])
        XCTAssertTrue(store.isFavorite(appId: "netflix"))

        store.unpinFavorite(appId: "netflix")
        XCTAssertEqual(store.favoriteAppIds(), ["youtube"])
        XCTAssertFalse(store.isFavorite(appId: "netflix"))

        store.recordLaunch(appId: "netflix")
        store.recordLaunch(appId: "youtube")
        store.recordLaunch(appId: "netflix")
        XCTAssertEqual(store.recentAppIds(), ["netflix", "youtube"])
    }
}
