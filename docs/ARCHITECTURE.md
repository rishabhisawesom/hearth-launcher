# Architecture

Hearth is a SwiftUI macOS shell for Apple Silicon Mac minis used as living-room computers.

## Stack

- Swift, SwiftUI, AppKit (boundaries only)
- MVVM, SPM feature modules, dependency injection
- SwiftData, Core Bluetooth (iPhone remote)

## Modules (planned)

- CoreUI, CoreNavigation, CoreSystem
- FeatureHome, FeatureApplications, FeatureStreaming, FeatureSearch, FeatureVoice, FeatureSettings, FeatureRemote
- RemoteProtocol, DataPersistence, ImagePipeline

See the Linear project **Convert Mac Mini into a TV** for the full implementation sequence.
