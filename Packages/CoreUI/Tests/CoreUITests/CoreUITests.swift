import XCTest
@testable import CoreUI

final class CoreUITests: XCTestCase {
    func testVersion() {
        XCTAssertEqual(CoreUI.version, "0.1.0")
    }
}
