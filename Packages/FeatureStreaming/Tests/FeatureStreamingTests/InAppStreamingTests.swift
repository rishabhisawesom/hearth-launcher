import XCTest
@testable import FeatureStreaming

final class InAppStreamingTests: XCTestCase {
    func testYouTubeHasInAppURL() {
        XCTAssertEqual(
            InAppStreaming.url(for: "youtube")?.absoluteString,
            "https://www.youtube.com/tv"
        )
        XCTAssertEqual(
            InAppStreaming.userAgent(for: "youtube"),
            "Mozilla/5.0 (ChromiumStylePlatform) Cobalt/Version"
        )
    }

    func testOtherAppsHaveNoInAppURL() {
        XCTAssertNil(InAppStreaming.url(for: "netflix"))
        XCTAssertNil(InAppStreaming.url(for: "prime-video"))
        XCTAssertNil(InAppStreaming.url(for: "hotstar"))
    }

    func testLeanbackDisabledForYouTube() {
        XCTAssertFalse(InAppStreaming.leanbackEnabled(for: "youtube"))
    }
}
