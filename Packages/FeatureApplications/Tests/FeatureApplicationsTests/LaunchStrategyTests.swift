import XCTest
@testable import FeatureApplications

final class LaunchStrategyTests: XCTestCase {
    func testPreferNativeAppUsesWebWhenAppMissing() {
        LaunchStrategyPreferences.strategy = .preferNativeApp
        let app = CuratedApps.streaming[0]
        XCTAssertEqual(LaunchStrategyResolver.launchURL(for: app), app.launchURL())
    }

    func testBrowserOnlyUsesWebURL() {
        LaunchStrategyPreferences.strategy = .browserOnly
        let app = CuratedApps.streaming[0]
        XCTAssertEqual(LaunchStrategyResolver.launchURL(for: app), app.webURL)
        LaunchStrategyPreferences.strategy = .preferNativeApp
    }
}
