# Setup

## Developer

1. Clone the repo
2. Requires macOS 15+, Apple Silicon, and Xcode 16+ (or Swift toolchain from Command Line Tools)

### Run in Xcode

1. Open `Package.swift` in Xcode (File → Open → select `Package.swift`)
2. Select the **Hearth** scheme in the toolbar
3. Press **⌘R** (Run)

You should see a dark SwiftUI window titled **Hearth** with a module version footer.

### Run from Terminal

```bash
swift build
.build/debug/Hearth
```

You should see the same Hearth window launch from the built executable.

To run tests from the repo root:

```bash
swift test
```

Tests also live under `Packages/*/Tests` — run per package with `swift test --package-path Packages/<Name>`.

## Living-room Mac mini (planned)

1. Create a dedicated macOS user account
2. Enable auto-login for that user
3. Add Hearth as a login item
4. Enable Bluetooth for iPhone remote pairing

Details will expand as kiosk mode lands in M1.
