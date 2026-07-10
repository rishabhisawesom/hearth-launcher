import XCTest
@testable import FeatureStreaming

final class PrimeDOMCatalogParserTests: XCTestCase {
    func testParsesDomCatalogFixture() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "prime_dom_catalog", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let jsonString = try XCTUnwrap(String(data: data, encoding: .utf8))
        let catalog = PrimeDOMCatalogParser.parse(jsonString: jsonString)

        XCTAssertEqual(catalog.rows.count, 2)

        let trending = try XCTUnwrap(catalog.rows.first { $0.title == "Trending now" })
        XCTAssertEqual(trending.tiles.count, 3)
        XCTAssertEqual(trending.tiles[0].title, "Raakh - Season 1")
        XCTAssertEqual(
            trending.tiles[0].detailURL?.absoluteString,
            "https://www.primevideo.com/detail/0FB3Z6GESMKM5UFHF6QNBGVVOU?ref=atv_hm"
        )
        XCTAssertEqual(
            trending.tiles[0].posterURL?.absoluteString,
            "https://images-eu.ssl-images-amazon.com/images/S/pv-target-images/raakh_SX624_FMjpg_.jpg"
        )

        let boys = try XCTUnwrap(trending.tiles.first { $0.title == "The Boys - Season 4" })
        XCTAssertTrue(boys.posterURL?.absoluteString.contains("SX899") == true)

        let recent = try XCTUnwrap(catalog.rows.first { $0.title == "Recently added" })
        XCTAssertEqual(recent.tiles.count, 2)
        XCTAssertEqual(recent.tiles[0].title, "Invincible - Season 3")
    }

    func testFixtureHTMLDocumentsExpectedShape() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "prime_dom_cards", withExtension: "html"))
        let html = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(html.contains("data-testid=\"card-container-list\""))
        XCTAssertTrue(html.contains("data-testid=\"card\""))
        XCTAssertTrue(html.contains("data-card-title=\"Raakh - Season 1\""))
        XCTAssertTrue(html.contains("images-eu.ssl-images-amazon.com"))
        XCTAssertTrue(html.contains("/detail/0FB3Z6GESMKM5UFHF6QNBGVVOU"))
    }

    func testEmptyOrInvalidReturnsEmptyCatalog() {
        XCTAssertTrue(PrimeDOMCatalogParser.parse(jsonString: "").isEmpty)
        XCTAssertTrue(PrimeDOMCatalogParser.parse(jsonString: "not json").isEmpty)
        XCTAssertTrue(PrimeDOMCatalogParser.parse(jsonString: "{\"rows\":[]}").isEmpty)
    }
}
