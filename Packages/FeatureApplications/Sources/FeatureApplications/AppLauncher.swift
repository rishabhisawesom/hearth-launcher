import AppKit

public enum AppLauncher {
    @MainActor
    public static func launch(_ app: CuratedApp) -> Bool {
        guard let url = app.resolveURL() else { return false }
        return NSWorkspace.shared.open(url)
    }
}
