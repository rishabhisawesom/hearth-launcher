import XCTest
@testable import CoreUI

final class CoreUITests: XCTestCase {
    func testVersion() {
        XCTAssertEqual(CoreUI.version, "0.1.0")
    }

    func testDesignTokensAreDefined() {
        XCTAssertNotNil(HearthColors.background)
        XCTAssertNotNil(HearthColors.surface)
        XCTAssertNotNil(HearthColors.accent)
        XCTAssertNotNil(HearthColors.textPrimary)
        XCTAssertNotNil(HearthColors.textSecondary)
        XCTAssertNotNil(HearthTypography.title)
        XCTAssertNotNil(HearthTypography.body)
        XCTAssertNotNil(HearthTypography.caption)
    }
}
