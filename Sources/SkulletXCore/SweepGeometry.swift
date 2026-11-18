import CoreGraphics
import Foundation

/// One pane under a sweep: its own box, and the box the front crosses. Both in the same space.
public struct SweepPane: Equatable, Sendable {
    public var rect: CGRect
    public var reveal: CGRect

    public init(rect: CGRect, reveal: CGRect) {
        self.rect = rect
        self.reveal = reveal
    }
}

/// The diagonal front of a sweep, as numbers only: no UIKit, no Metal, no platform types.
///
/// Ported one to one from Skullet's `sweep.ts` / `shimmer.ts`: the front is the line of constant
/// `u = x + y * tan(20°)`, and every mask is a ramp of `feather` points around it.
public enum SweepGeometry {
    /// Degrees from vertical, top right to bottom left.
    public static let slantDegrees: CGFloat = 20
    /// Softness of the front, points either side of it.
    public static let feather: CGFloat = 40
    /// Stops per ramp: enough for the eased curve to read as one.
    public static let steps = 12
    /// Width of the light band trailing the front, across the slant.
    public static let glossWidth: CGFloat = 320
    /// How far the band's centre trails the front.
    public static let glossLag: CGFloat = 120
    /// How far the band lifts what it crosses toward white.
    public static let glossLift: CGFloat = 0.45

    public static let sinSlant: CGFloat = .init(sin(slantDegrees * Double.pi / 180))
    public static let cosSlant: CGFloat = .init(cos(slantDegrees * Double.pi / 180))
    public static let tanSlant = sinSlant / cosSlant
    /// The feather, along `u`.
    public static let pad = feather / cosSlant

    public static func u(x: CGFloat, y: CGFloat) -> CGFloat {
        x + y * tanSlant
    }

    public static func u(_ point: CGPoint) -> CGFloat {
        u(x: point.x, y: point.y)
    }

    public static func span(width: CGFloat, height: CGFloat) -> CGFloat {
        width + height * tanSlant
    }

    /// Length of a box's shadow on the slant axis, in points.
    public static func axis(width: CGFloat, height: CGFloat) -> CGFloat {
        width * sinSlant + height * cosSlant
    }

    public static func ease(_ t: CGFloat) -> CGFloat {
        (1 - cos(Double.pi * min(max(t, 0), 1))) / 2
    }

    /// The front's `u` at `progress`, from a feather before the reveal to a feather past it.
    public static func front(progress: CGFloat, pane: SweepPane) -> CGFloat {
        let from = u(pane.reveal.origin)
        let across = span(width: pane.reveal.width, height: pane.reveal.height)
        return from - pad + (across + 2 * pad) * min(max(progress, 0), 1)
    }

    /// Mask stops for one pane: `locations` 0...1 along the slant, `alphas` 0...1 of black.
    public static func mask(
        progress: CGFloat,
        pane: SweepPane,
        incoming: Bool
    ) -> (locations: [CGFloat], alphas: [CGFloat]) {
        let axis = axis(width: pane.rect.width, height: pane.rect.height)
        guard axis > 0 else { return ([0, 1], incoming ? [1, 1] : [0, 0]) }

        let at = (front(progress: progress, pane: pane) - u(pane.rect.origin)) * cosSlant
        var locations: [CGFloat] = [0]
        var alphas: [CGFloat] = [incoming ? 1 : 0]
        for step in 0 ... steps {
            let t = CGFloat(step) / CGFloat(steps)
            locations.append(clamp01((at + (-feather + 2 * feather * t) * cosSlant) / axis))
            alphas.append(incoming ? 1 - ease(t) : ease(t))
        }
        locations.append(1)
        alphas.append(incoming ? 0 : 1)
        return (locations, alphas)
    }

    /// The band trailing the front, as white alphas over the pane.
    public static func gloss(
        progress: CGFloat,
        pane: SweepPane
    ) -> (locations: [CGFloat], alphas: [CGFloat]) {
        let axis = axis(width: pane.rect.width, height: pane.rect.height)
        guard axis > 0 else { return ([0, 1], [0, 0]) }

        let centre = front(progress: progress, pane: pane) - glossLag / cosSlant
        let half = glossWidth / 2 / cosSlant
        let from = (centre - half - u(pane.rect.origin)) * cosSlant
        let to = (centre + half - u(pane.rect.origin)) * cosSlant
        var locations: [CGFloat] = [0]
        var alphas: [CGFloat] = [0]
        for step in 0 ... steps {
            let t = CGFloat(step) / CGFloat(steps)
            locations.append(clamp01((from + (to - from) * t) / axis))
            alphas.append(ease(1 - abs(t * 2 - 1)) * glossLift)
        }
        locations.append(1)
        alphas.append(0)
        return (locations, alphas)
    }

    /// Gradient end points in unit space for a layer of `size`, so `locations` are measured along the slant.
    public static func gradientPoints(for size: CGSize) -> (start: CGPoint, end: CGPoint) {
        let axis = axis(width: size.width, height: size.height)
        guard size.width > 0, size.height > 0, axis > 0 else {
            return (.zero, CGPoint(x: 1, y: 0))
        }
        return (
            .zero,
            CGPoint(x: axis * sinSlant / size.width, y: axis * cosSlant / size.height)
        )
    }

    private static func clamp01(_ value: CGFloat) -> CGFloat {
        min(max(value, 0), 1)
    }
}
