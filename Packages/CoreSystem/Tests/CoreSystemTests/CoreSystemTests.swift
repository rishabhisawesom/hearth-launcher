import XCTest
@testable import CoreSystem

final class CoreSystemTests: XCTestCase {
    func testVersion() {
        XCTAssertEqual(CoreSystem.version, "0.1.0")
    }
}
