import XCTest
@testable import FeatureStreaming

final class NetflixCatalogParserTests: XCTestCase {
    func testParsesLolomoRowsFromFixture() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "netflix_catalog_sample", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let catalog = NetflixCatalogParser.parse(data: data)

        XCTAssertGreaterThanOrEqual(catalog.rows.count, 2)

        let trending = try XCTUnwrap(catalog.rows.first { $0.title == "Trending Now" })
        XCTAssertEqual(trending.tiles.count, 3)
        XCTAssertEqual(trending.tiles.first?.title, "Stranger Things")
        XCTAssertEqual(
            trending.tiles.first?.detailURL?.absoluteString,
            "https://www.netflix.com/watch/80057281"
        )

        let recent = try XCTUnwrap(catalog.rows.first { $0.title == "New on Netflix" })
        XCTAssertEqual(recent.tiles.count, 3)
        XCTAssertEqual(recent.tiles[0].title, "The Crown")
        XCTAssertEqual(
            recent.tiles[0].detailURL?.absoluteString,
            "https://www.netflix.com/watch/80025678"
        )
    }

    func testParsesOrphanTilesIntoBrowseRow() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "netflix_catalog_sample", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let catalog = NetflixCatalogParser.parse(data: data)

        XCTAssertTrue(catalog.rows.contains { $0.tiles.contains { $0.title == "Standalone Film" } })
    }

    func testEmptyJSONReturnsEmptyCatalog() {
        XCTAssertTrue(NetflixCatalogParser.parse(jsonString: "").isEmpty)
        XCTAssertTrue(NetflixCatalogParser.parse(jsonString: "not json").isEmpty)
    }
}
