import XCTest
@testable import RemoteProtocol

final class RemoteProtocolTests: XCTestCase {
    func testServiceName() {
        XCTAssertEqual(RemoteProtocolKit.serviceName, "Hearth")
    }

    func testSelectMessage() {
        XCTAssertEqual(RemoteMessage.select, .select)
    }
}
