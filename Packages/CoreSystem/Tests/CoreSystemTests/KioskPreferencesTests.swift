import XCTest
@testable import CoreSystem

final class KioskPreferencesTests: XCTestCase {
    func testHideSystemChromeDefaultsTrue() {
        let defaults = UserDefaults.standard
        let key = "hideSystemChrome"
        let prior = defaults.object(forKey: key)
        defer {
            if let prior {
                defaults.set(prior, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }

        defaults.removeObject(forKey: key)
        XCTAssertTrue(KioskPreferences.hideSystemChrome)

        KioskPreferences.hideSystemChrome = false
        XCTAssertFalse(KioskPreferences.hideSystemChrome)
    }
}
