# Hearth

A premium, open-source macOS launcher that turns an Apple Silicon Mac mini into a true living-room experience — fullscreen, couch-friendly, and Bluetooth-remote ready.

## Requirements

- macOS 15+
- Apple Silicon (M-series) only
- Xcode 16+

## Status

M0 scaffold: SwiftPM workspace with Hearth executable and CoreUI, CoreNavigation, CoreSystem, RemoteProtocol packages.

## Run

### Run in Xcode

Open `Package.swift`, select the **Hearth** scheme, press **⌘R**.

### Run from Terminal

```bash
swift build && .build/debug/Hearth
```

See [Setup](docs/SETUP.md) for details and what you should see.

## Docs

- [Architecture](docs/ARCHITECTURE.md)
- [Roadmap](docs/ROADMAP.md)
- [Setup](docs/SETUP.md)
- [Contributing](CONTRIBUTING.md)

## License

MIT
