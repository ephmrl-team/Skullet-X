import CoreGraphics
import Foundation

/// How content replaces its skeleton.
public enum RevealKind: Equatable, Sendable {
    case instant
    case crossfade
    case sweep
}

/// What a reveal knows as its content lands.
public struct RevealContext: Sendable {
    /// Seconds the skeleton was up; `.infinity` when there was none.
    public var waited: CFTimeInterval = .infinity
    /// Someone scrolled or typed recently.
    public var input = false
    /// The skeleton was drawn from the data on screen.
    public var refetch = false
    public var pane: SweepPane
    public var screen: CGRect
    /// The shimmer's loop, when one runs.
    public var shimmerDuration: CFTimeInterval?

    public init(pane: SweepPane, screen: CGRect) {
        self.pane = pane
        self.screen = screen
    }
}

/// The cases Skullet's `smart` settles before it looks at the content.
public enum RevealPolicy {
    /// A skeleton up for less than this is a flash: hold it back, so a fast load never shows one.
    public static let hold: CFTimeInterval = 0.15
    public static let fade: CFTimeInterval = 0.2
    /// A refetch is familiar already.
    public static let quickFade: CFTimeInterval = 0.12
    /// Input this recent means someone is mid-gesture.
    public static let activeWindow: CFTimeInterval = 0.4

    public static func choose(_ context: RevealContext) -> RevealKind {
        if context.input || context.waited < hold {
            return .instant
        }
        if context.refetch {
            return .crossfade
        }
        guard let shimmer = context.shimmerDuration, shimmer > 0 else { return .crossfade }
        let area = context.pane.reveal.width * context.pane.reveal.height
        guard area > 0, area <= context.screen.width * context.screen.height * SweepClock.maxSweepArea
        else { return .crossfade }
        return .sweep
    }
}
