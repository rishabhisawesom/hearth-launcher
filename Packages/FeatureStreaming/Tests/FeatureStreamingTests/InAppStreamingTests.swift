import XCTest
@testable import FeatureStreaming

final class InAppStreamingTests: XCTestCase {
    func testYouTubeHasInAppURL() {
        XCTAssertEqual(
            InAppStreaming.url(for: "youtube")?.absoluteString,
            "https://www.youtube.com/tv"
        )
    }

    func testNetflixHasInAppURL() {
        XCTAssertEqual(
            InAppStreaming.url(for: "netflix")?.absoluteString,
            "https://www.netflix.com/browse"
        )
    }

    func testOtherAppsHaveNoInAppURL() {
        XCTAssertNil(InAppStreaming.url(for: "prime-video"))
        XCTAssertNil(InAppStreaming.url(for: "hotstar"))
    }

    func testNativeBrowseForNetflix() {
        XCTAssertEqual(InAppStreaming.experienceKind(for: "netflix"), .nativeBrowse)
        XCTAssertEqual(InAppStreaming.experienceKind(for: "youtube"), .webShell)
    }
}
