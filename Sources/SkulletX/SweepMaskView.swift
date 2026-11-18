#if canImport(SwiftUI) && canImport(UIKit)
    import SkulletXCore
    import SwiftUI

    /// A pane's slice of the sweep, as a gradient: black for a mask, white for the gloss.
    struct SweepMaskView: View {
        let stops: (locations: [CGFloat], alphas: [CGFloat])
        let size: CGSize
        let white: Bool

        var body: some View {
            let points = SweepGeometry.gradientPoints(for: size)
            LinearGradient(
                stops: gradientStops,
                startPoint: UnitPoint(x: points.start.x, y: points.start.y),
                endPoint: UnitPoint(x: points.end.x, y: points.end.y)
            )
        }

        private var gradientStops: [Gradient.Stop] {
            var result: [Gradient.Stop] = []
            var last: CGFloat = -1
            for (location, alpha) in zip(stops.locations, stops.alphas) {
                let value = min(max(location, 0), 1)
                // SwiftUI wants increasing locations; clamped duplicates add nothing.
                guard value > last else { continue }
                result.append(
                    Gradient.Stop(
                        color: (white ? Color.white : Color.black).opacity(Double(alpha)),
                        location: Double(value)
                    )
                )
                last = value
            }
            return result.isEmpty ? [Gradient.Stop(color: .clear, location: 0)] : result
        }
    }
#endif
