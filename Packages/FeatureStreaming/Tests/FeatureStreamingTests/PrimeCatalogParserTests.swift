import XCTest
@testable import FeatureStreaming

final class PrimeCatalogParserTests: XCTestCase {
    func testParsesRowArraysFromFixture() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "prime_catalog_sample", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let catalog = PrimeCatalogParser.parse(data: data)

        XCTAssertGreaterThanOrEqual(catalog.rows.count, 2)

        let trending = try XCTUnwrap(catalog.rows.first { $0.title == "Trending now" })
        XCTAssertEqual(trending.tiles.count, 3)
        XCTAssertEqual(trending.tiles.first?.title, "The Boys")
        XCTAssertEqual(
            trending.tiles.first?.detailURL?.absoluteString,
            "https://www.primevideo.com/detail/0KAJ123"
        )

        let recent = try XCTUnwrap(catalog.rows.first { $0.title == "Recently added" })
        XCTAssertEqual(recent.tiles.count, 3)
        XCTAssertEqual(recent.tiles[0].title, "Invincible")
        XCTAssertEqual(
            recent.tiles[0].detailURL?.absoluteString,
            "https://www.primevideo.com/detail/0KAJABC"
        )
    }

    func testParsesOrphanTilesIntoBrowseRow() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "prime_catalog_sample", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let catalog = PrimeCatalogParser.parse(data: data)

        XCTAssertTrue(catalog.rows.contains { $0.tiles.contains { $0.title == "Standalone Movie" } })
    }

    func testEmptyJSONReturnsEmptyCatalog() {
        XCTAssertTrue(PrimeCatalogParser.parse(jsonString: "").isEmpty)
        XCTAssertTrue(PrimeCatalogParser.parse(jsonString: "not json").isEmpty)
    }
}
