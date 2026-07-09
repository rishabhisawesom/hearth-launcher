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

    func testLaunchURLFallsBackToWeb() {
        let app = CuratedApps.streaming[0]
        XCTAssertEqual(app.launchURL(), app.webURL)
    }
}
