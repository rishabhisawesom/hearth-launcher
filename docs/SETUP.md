# Setup

## Developer

1. Clone the repo
2. Requires macOS 15+, Apple Silicon, and Xcode 16+ (or Swift toolchain from Command Line Tools)

### Run in Xcode

1. Open `Package.swift` in Xcode (File → Open → select `Package.swift`)
2. Select the **Hearth** scheme in the toolbar
3. Press **⌘R** (Run)

You should see a fullscreen dark UI with a tile grid. Use arrow keys to move focus.

### Run from Terminal

```bash
swift build
.build/debug/Hearth
```

Quit when done: close the app, use **Quit Hearth** in Settings (⌘,), or `pkill -f ".build/debug/Hearth"`.

To run tests per package:

```bash
swift test --package-path Packages/CoreUI
swift test --package-path Packages/CoreNavigation
swift test --package-path Packages/CoreSystem
swift test --package-path Packages/RemoteProtocol
```

## Living-room Mac mini

Set up a dedicated TV user so Hearth can own the screen at boot.

### 1. Create a dedicated user

1. **System Settings → Users & Groups → Add Account**
2. Name it e.g. `Living Room` (standard user is fine)
3. Sign in once to complete setup, then use this account for the Mac mini on the TV

### 2. Enable auto-login

1. **System Settings → Users & Groups → Login Options**
2. Set **Automatic login** to the living-room user
3. Reboot once to confirm the account logs in without a password prompt

### 3. Install and launch Hearth

**Development build:**

```bash
swift build
.build/debug/Hearth
```

**Production:** install a signed `Hearth.app` to `/Applications` (notarization guide coming in M7).

### 4. Configure kiosk mode in Hearth

Open **Settings** with **⌘,** while Hearth is focused:

| Setting | Purpose |
|---------|---------|
| **Hide Dock and menu bar** | Fullscreen TV experience (on by default) |
| **Launch at login** | Start Hearth when the living-room user logs in |
| **Quit Hearth** | Escape hatch to exit the launcher |

> **Note:** **Launch at login** requires a proper `.app` bundle. The raw `swift build` binary may fail to register — use a packaged app for production.

### 5. Escape hatch

Hearth is a kiosk shell, not a lockdown:

- **⌘Tab** — switch to another app
- **⌘,** — open Hearth Settings
- **Quit Hearth** — exit completely

To return to normal macOS, quit Hearth or reboot and sign into a different user.

### 6. Bluetooth (iPhone remote)

Enable Bluetooth on the Mac mini. iPhone companion app pairing lands in M5–M6.

## Manual acceptance test (M1 exit)

Run on real hardware before closing M1:

1. Reboot the Mac mini
2. Living-room user auto-logs in
3. Hearth launches fullscreen with no menu bar or Dock
4. Arrow keys move focus across the tile grid
5. **⌘,** opens Settings; toggles work
6. **Quit Hearth** exits cleanly

Record results in Linear **RIS-45**.

## M2 performance smoke

On Mac mini hardware with the home screen open:

1. Arrow through all visible sections and tiles — focus should update instantly with no visible stutter
2. Horizontal rows with 4 tiles should scroll smoothly when focused tile is near the edge
3. Optional: Instruments → Time Profiler while navigating; target 60 FPS sustained

Record results in Linear **RIS-65**.

## Streaming launch (M3)

Hearth ships four streaming tiles: Netflix, Prime Video, YouTube, and Hotstar.

**Launch behavior** (Settings → Streaming launch):

| Mode | Behavior |
|------|----------|
| Prefer app, else browser | Opens the native `.app` if installed in `/Applications`, otherwise the service website |
| Browser only | Always opens the website in your default browser |

**PWA / Safari profile:** For a dedicated living-room browser profile, create a macOS user or Safari profile manually and set it as the default browser. Automated profile wizard is deferred.

**Return to Hearth after streaming:** Not automated yet — use **⌘,** → Quit Hearth, or switch back with the keyboard/remote when the browser app closes.

## Themes & wallpaper (M4)

**Theme** (Settings → Theme): Dark (default), Light, OLED Dark (true black).

**Wallpaper** (Settings → Wallpaper): Solid or Gradient (blurred theme-colored gradient behind tiles). Changes apply immediately when Settings closes.

External image APIs (Unsplash/Pexels) and parallax motion are deferred.
