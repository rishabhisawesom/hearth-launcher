import XCTest
@testable import FeatureApplications

final class SearchIndexTests: XCTestCase {
    func testEmptyQueryReturnsNoResults() {
        XCTAssertTrue(SearchIndex.search("").isEmpty)
        XCTAssertTrue(SearchIndex.search("   ").isEmpty)
    }

    func testMatchesAppNameSubstring() {
        let results = SearchIndex.search("flix")
        XCTAssertEqual(results.map(\.title), ["Netflix"])
    }

    func testCaseInsensitiveMatch() {
        let results = SearchIndex.search("YOUTUBE")
        XCTAssertEqual(results.map(\.title), ["YouTube"])
    }

    func testNoMatchReturnsEmpty() {
        XCTAssertTrue(SearchIndex.search("hulu").isEmpty)
    }
}
