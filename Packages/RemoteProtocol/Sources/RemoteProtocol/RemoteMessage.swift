public enum RemoteMessage: Sendable, Equatable {
    case navigate(FocusDirection)
    case select
    case back
    case home
}

public enum FocusDirection: Sendable, Equatable {
    case up, down, left, right
}
