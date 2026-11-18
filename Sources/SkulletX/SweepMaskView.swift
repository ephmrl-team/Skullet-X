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
            for (location, alpha) in zip(stops.locations, stops.alphas) {
                let value = min(max(location, 0), 1)
                if let index = result.indices.last, result[index].location == Double(value) {
                    // Stops that clamp onto an edge must keep the alpha the ramp has at that edge:
                    // the later stop for 0 (the ramp is entering), the earlier one for 1 (leaving).
                    if value == 0 {
                        result[index] = stop(alpha: alpha, at: value)
                    }
                    continue
                }
                result.append(stop(alpha: alpha, at: value))
            }
            return result.isEmpty ? [Gradient.Stop(color: .clear, location: 0)] : result
        }

        private func stop(alpha: CGFloat, at location: CGFloat) -> Gradient.Stop {
            Gradient.Stop(
                color: (white ? Color.white : Color.black).opacity(Double(alpha)),
                location: Double(location)
            )
        }
    }
#endif
