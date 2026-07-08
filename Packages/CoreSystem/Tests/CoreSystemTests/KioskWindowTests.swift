import AppKit
import XCTest
@testable import CoreSystem

@MainActor
final class KioskWindowTests: XCTestCase {
    func testKeyableWindowCanBecomeKeyAndMain() {
        let window = KeyableWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        XCTAssertTrue(window.canBecomeKey)
        XCTAssertTrue(window.canBecomeMain)
    }

    func testConfigureAppliesKioskWindowFlags() {
        let window = KeyableWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )

        KioskWindow.configure(window, hideChrome: false)

        XCTAssertTrue(window.styleMask.contains(.borderless))
        XCTAssertTrue(window.styleMask.contains(.fullSizeContentView))
        XCTAssertFalse(window.isMovable)
        XCTAssertEqual(window.titleVisibility, .hidden)
        XCTAssertEqual(window.backgroundColor, .black)
    }
}
