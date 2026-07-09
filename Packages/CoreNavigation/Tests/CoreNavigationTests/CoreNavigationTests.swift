import XCTest
@testable import CoreNavigation

final class CoreNavigationTests: XCTestCase {
    func testFocusGridMovesRightAndLeft() {
        XCTAssertEqual(FocusGrid.moved(from: 1, columns: 4, itemCount: 8, direction: .right), 2)
        XCTAssertEqual(FocusGrid.moved(from: 1, columns: 4, itemCount: 8, direction: .left), 0)
    }

    func testFocusGridMovesDownAndUp() {
        XCTAssertEqual(FocusGrid.moved(from: 1, columns: 4, itemCount: 8, direction: .down), 5)
        XCTAssertEqual(FocusGrid.moved(from: 5, columns: 4, itemCount: 8, direction: .up), 1)
    }

    func testFocusGridClampsAtEdges() {
        XCTAssertEqual(FocusGrid.moved(from: 0, columns: 4, itemCount: 8, direction: .left), 0)
        XCTAssertEqual(FocusGrid.moved(from: 7, columns: 4, itemCount: 8, direction: .right), 7)
        XCTAssertEqual(FocusGrid.moved(from: 6, columns: 4, itemCount: 8, direction: .down), 6)
    }

    func testFocusSectionsMovesWithinRow() {
        let counts = [4, 3]
        XCTAssertEqual(FocusSections.moved(section: 0, tile: 1, itemCounts: counts, direction: .right), (0, 2))
        XCTAssertEqual(FocusSections.moved(section: 0, tile: 1, itemCounts: counts, direction: .left), (0, 0))
    }

    func testFocusSectionsMovesBetweenSections() {
        let counts = [4, 3]
        XCTAssertEqual(FocusSections.moved(section: 0, tile: 2, itemCounts: counts, direction: .down), (1, 2))
        XCTAssertEqual(FocusSections.moved(section: 1, tile: 2, itemCounts: counts, direction: .up), (0, 2))
    }

    func testFocusSectionsClampsColumnAcrossSections() {
        let counts = [4, 2]
        XCTAssertEqual(FocusSections.moved(section: 0, tile: 3, itemCounts: counts, direction: .down), (1, 1))
    }
}
