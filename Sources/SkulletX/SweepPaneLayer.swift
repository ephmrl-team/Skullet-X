#if canImport(UIKit)
    import QuartzCore
    import SkulletXCore
    import UIKit

    /// Draws one pane's slice of a sweep: its mask, and the light band trailing the front.
    final class SweepPaneLayer {
        private let host: CALayer
        private let mask = CAGradientLayer()
        private let gloss = CAGradientLayer()
        private var glossAdded = false

        init(host: CALayer) {
            self.host = host
            mask.type = .axial
            gloss.type = .axial
            gloss.isHidden = true
        }

        func apply(progress: CGFloat, pane: SweepPane, incoming: Bool, glossing: Bool) {
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

            if glossing {
                if !glossAdded {
                    host.addSublayer(gloss)
                    glossAdded = true
                }
                let band = SweepGeometry.gloss(progress: progress, pane: pane)
                gloss.frame = host.bounds
                gloss.startPoint = points.start
                gloss.endPoint = points.end
                gloss.colors = band.alphas.map { UIColor.white.withAlphaComponent($0).cgColor }
                gloss.locations = band.locations.map { NSNumber(value: Double($0)) }
                gloss.isHidden = false
            }
            CATransaction.commit()
        }

        func clear() {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            host.mask = nil
            if glossAdded {
                gloss.removeFromSuperlayer()
                glossAdded = false
            }
            CATransaction.commit()
        }
    }

#endif
