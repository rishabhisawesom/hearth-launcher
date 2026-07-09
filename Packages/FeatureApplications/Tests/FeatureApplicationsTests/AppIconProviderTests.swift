import XCTest
@testable import FeatureApplications

final class AppIconProviderTests: XCTestCase {
    func testFallbackSymbolName() {
        XCTAssertEqual(AppIconProvider.fallbackSymbolName, "play.rectangle.fill")
    }
}
