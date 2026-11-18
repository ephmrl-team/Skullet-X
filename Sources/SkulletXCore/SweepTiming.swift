import CoreGraphics
import Foundation

/// The one front a batch of reveals shares: where it started, and how fast it runs along `u`.
public struct SweepWave: Equatable, Sendable {
    public var start: CFTimeInterval
    public var origin: CGFloat
    /// Points per second along `u`.
    public var speed: CGFloat

    public init(start: CFTimeInterval, origin: CGFloat, speed: CGFloat) {
        self.start = start
        self.origin = origin
        self.speed = speed
    }
}

/// When a sweep reaches a pane, and how long it takes across it.
///
/// Numbers from Skullet's `sweep.ts`: a front runs at twice the shimmer's pace, and a reveal that
/// lands within `batchWindow` of another joins the front already under way if it isn't kept waiting.
public struct SweepClock: Sendable {
    public static let shimmerSlow: CFTimeInterval = 4
    public static let shimmerFast: CFTimeInterval = 2
    /// A shimmer's loop is measured across this width, so a wide screen doesn't make it race.
    public static let referenceWidth: CGFloat = 1280
    public static let maxBand: CGFloat = 320
    /// Of a shimmer's loop, the share a sweep takes at the reference width.
    public static let sweepShare: CGFloat = 0.7
    public static let wavePace: CGFloat = 2
    /// Most a sweep takes across the reveal that starts it.
    public static let waveSpread: CGFloat = 360
    /// Most a sweep takes across a reveal that joins one under way.
    public static let sweepSpread: CGFloat = 600
    public static let batchWindow: CFTimeInterval = 0.15
    /// A wipe bigger than this many screens crossfades instead.
    public static let maxSweepArea: CGFloat = 1.5
    /// Seconds between frames that count as frames dropping.
    public static let stall: CFTimeInterval = 0.1

    public var wave: SweepWave?

    public init(wave: SweepWave? = nil) {
        self.wave = wave
    }

    /// Seconds per point along `u`, from the shimmer's loop.
    public static func pace(shimmerDuration: CFTimeInterval) -> CGFloat {
        CGFloat(shimmerDuration) * sweepShare / (referenceWidth + maxBand)
    }

    public static func progress(
        now: CFTimeInterval,
        start: CFTimeInterval,
        duration: CFTimeInterval
    ) -> CGFloat {
        guard duration > 0 else { return 1 }
        return min(max(CGFloat((now - start) / duration), 0), 1)
    }

    /// Delay and duration for `pane`; nil when the pane is too big to sweep.
    public mutating func timing(
        for pane: SweepPane,
        now: CFTimeInterval,
        shimmerDuration: CFTimeInterval,
        screen: CGRect
    ) -> (delay: CFTimeInterval, duration: CFTimeInterval)? {
        let reveal = pane.reveal
        guard reveal.width > 0, reveal.height > 0,
              reveal.width * reveal.height <= screen.width * screen.height * Self.maxSweepArea
        else { return nil }

        let pace = Self.pace(shimmerDuration: shimmerDuration)
        guard pace > 0 else { return nil }

        let from = SweepGeometry.u(reveal.origin)
        let to = from + SweepGeometry.span(width: reveal.width, height: reveal.height)
        let speed = max(Self.wavePace / pace, (to - from) / Self.waveSpread)

        let keep = wave.map { Self.joins($0, now: now, from: from, to: to) } ?? false
        if !keep {
            wave = SweepWave(start: now, origin: from, speed: speed)
        }
        guard let active = wave else { return nil }

        let delay = CFTimeInterval((from - SweepGeometry.pad - active.origin) / active.speed)
            - (now - active.start)
        let duration = CFTimeInterval((to - from + 2 * SweepGeometry.pad) / active.speed)
        return (delay, duration)
    }

    /// A reveal landing within the batch window joins a front that hasn't passed it and won't keep it waiting.
    private static func joins(_ wave: SweepWave, now: CFTimeInterval, from: CGFloat, to: CGFloat) -> Bool {
        let elapsed = CGFloat(now - wave.start)
        let reaches = (from - wave.origin) / wave.speed
        let clears = (to - wave.origin) / wave.speed
        return elapsed <= batchWindow
            && reaches >= elapsed
            && clears - elapsed <= sweepSpread
    }
}
