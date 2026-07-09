import XCTest
@testable import FeatureApplications

final class StreamingSectionProviderTests: XCTestCase {
    func testStreamingSectionProvider() {
        let provider = StreamingSectionProvider()
        XCTAssertEqual(provider.sections.count, 1)

        let section = provider.sections[0]
        XCTAssertEqual(section.id, "streaming")
        XCTAssertEqual(section.title, "Streaming")
        XCTAssertEqual(section.tiles.map(\.title), CuratedApps.streaming.map(\.name))
        XCTAssertEqual(section.tiles.compactMap(\.app), CuratedApps.streaming)
    }
}
