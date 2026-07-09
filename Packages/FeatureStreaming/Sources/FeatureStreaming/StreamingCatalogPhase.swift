import Foundation

public enum StreamingCatalogPhase: Equatable, Sendable {
    case loading
    case needsLogin
    case ready
    case empty
}
