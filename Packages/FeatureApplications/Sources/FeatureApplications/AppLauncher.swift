import AppKit

public enum AppLauncher {
    @MainActor
    public static func launch(_ app: CuratedApp) -> Bool {
        let success = NSWorkspace.shared.open(app.launchURL())
        if success {
            AppActivityStore.shared.recordLaunch(appId: app.id)
        }
        return success
    }
}
