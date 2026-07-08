import Foundation

public enum KioskPreferences {
    private static let hideChromeKey = "hideSystemChrome"

    public static var hideSystemChrome: Bool {
        get {
            UserDefaults.standard.object(forKey: hideChromeKey) as? Bool ?? true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hideChromeKey)
        }
    }
}
