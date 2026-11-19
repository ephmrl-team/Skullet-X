#if canImport(UIKit)
    import QuartzCore
    import SkulletXCore
    import UIKit

    /// Draws one pane's slice of a sweep as an alpha mask.
    final class SweepPaneLayer {
        private let host: CALayer
        private let mask = CAGradientLayer()

        init(host: CALayer) {
            self.host = host
            mask.type = .axial
        }

        func apply(progress: CGFloat, pane: SweepPane, incoming: Bool) {
            let points = SweepGeometry.gradientPoints(for: host.bounds.size)
            let maskStops = SweepGeometry.mask(progress: progress, pane: pane, incoming: incoming)

            CATransaction.begin()
            CATransaction.setDisableActions(true)
            mask.frame = host.bounds
            mask.startPoint = points.start
            mask.endPoint = points.end
            mask.colors = maskStops.alphas.map { UIColor.black.withAlphaComponent($0).cgColor }
            mask.locations = maskStops.locations.map { NSNumber(value: Double($0)) }
            host.mask = mask

            CATransaction.commit()
        }

        func clear() {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            host.mask = nil
            CATransaction.commit()
        }
    }

#endif
