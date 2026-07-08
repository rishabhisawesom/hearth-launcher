import XCTest
@testable import CoreNavigation

final class CoreNavigationTests: XCTestCase {
    func testFocusDirection() {
        XCTAssertEqual(FocusDirection.right, .right)
    }
}
