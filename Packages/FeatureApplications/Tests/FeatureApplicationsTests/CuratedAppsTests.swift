import XCTest
@testable import FeatureApplications

final class CuratedAppsTests: XCTestCase {
    func testStreamingAppsList() {
        XCTAssertEqual(CuratedApps.streaming.map(\.name), [
            "Netflix",
            "Prime Video",
            "YouTube",
            "Hotstar",
        ])
    }
}
