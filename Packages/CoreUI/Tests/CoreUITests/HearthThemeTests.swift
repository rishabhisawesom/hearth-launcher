import XCTest
@testable import CoreUI

final class HearthThemeTests: XCTestCase {
    func testThemesDiffer() {
        XCTAssertNotEqual(HearthTheme.dark.palette.background, HearthTheme.light.palette.background)
        XCTAssertNotEqual(HearthTheme.dark.palette.background, HearthTheme.oled.palette.background)
    }

    func testOLEDUsesTrueBlackBackground() {
        XCTAssertEqual(HearthTheme.oled.palette.background, .black)
    }

    func testWallpaperStylesRoundTrip() {
        for style in WallpaperStyle.allCases {
            XCTAssertEqual(WallpaperStyle(rawValue: style.rawValue), style)
        }
    }
}
