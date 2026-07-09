import XCTest
@testable import FeatureStreaming

final class InAppStreamingTests: XCTestCase {
    func testYouTubeHasInAppURL() {
        XCTAssertEqual(
            InAppStreaming.url(for: "youtube")?.absoluteString,
            "https://www.youtube.com/tv"
        )
    }

    func testPrimeVideoHasInAppURL() {
        XCTAssertEqual(
            InAppStreaming.url(for: "prime-video")?.absoluteString,
            "https://www.primevideo.com/tv"
        )
    }

    func testOtherAppsHaveNoInAppURL() {
        XCTAssertNil(InAppStreaming.url(for: "netflix"))
        XCTAssertNil(InAppStreaming.url(for: "hotstar"))
    }

    func testNativeBrowseForPrime() {
        XCTAssertEqual(InAppStreaming.experienceKind(for: "prime-video"), .nativeBrowse)
        XCTAssertEqual(InAppStreaming.experienceKind(for: "youtube"), .webShell)
    }
}
