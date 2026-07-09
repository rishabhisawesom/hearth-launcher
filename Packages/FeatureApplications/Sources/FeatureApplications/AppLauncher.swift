import AppKit

public enum AppLauncher {
    @MainActor
    public static func launch(_ app: CuratedApp) -> Bool {
        guard let url = app.resolveURL() else { return false }
        let success = NSWorkspace.shared.open(url)
        if success {
            AppActivityStore.shared.recordLaunch(appId: app.id)
        }
        return success
    }
}
