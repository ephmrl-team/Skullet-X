#if canImport(UIKit)
    import SkulletXCore
    import UIKit

    /// One bar of a skeleton: a rounded base with the page's shimmer crossing it.
    public final class SkeletonBarView: UIView {
        public var style = SkeletonStyle() {
            didSet { applyStyle(); restartShimmer() }
        }

        /// A circle whatever the style's radius says — an avatar.
        public var isCircular = false

        private let shine = CAGradientLayer()

        override public init(frame: CGRect) {
            super.init(frame: frame)
            setUp()
        }

        public required init?(coder: NSCoder) {
            super.init(coder: coder)
            setUp()
        }

        override public func layoutSubviews() {
            super.layoutSubviews()
            layer.cornerRadius = isCircular ? bounds.height / 2 : min(style.radius, bounds.height / 2)
            updateShine()
        }

        override public func didMoveToWindow() {
            super.didMoveToWindow()
            restartShimmer()
        }

        private func setUp() {
            isUserInteractionEnabled = false
            clipsToBounds = true
            layer.cornerCurve = .continuous
            layer.addSublayer(shine)
            applyStyle()
        }

        private func applyStyle() {
            backgroundColor = style.base
        }

        /// A band of the highlight, `period` apart, as wide as the shimmer's widest.
        private var tile: CGFloat {
            SweepClock.maxBand * 2.5 / SweepGeometry.cosSlant
        }

        private func updateShine() {
            let height = max(bounds.height, 1)
            shine.frame = CGRect(x: -tile, y: 0, width: tile * 2 + bounds.width, height: height)
            let points = SweepGeometry.gradientPoints(for: shine.bounds.size)
            shine.startPoint = points.start
            shine.endPoint = points.end
            let band = stops()
            shine.colors = band.colors
            shine.locations = band.locations
        }

        private func stops() -> (colors: [CGColor], locations: [NSNumber]) {
            let band = SweepClock.maxBand
            let period = band * 2.5
            let axis = tile * 2 * SweepGeometry.cosSlant
            var colors: [CGColor] = [UIColor.clear.cgColor]
            var locations: [NSNumber] = [0]
            for copy in 0 ..< 2 {
                let start = CGFloat(copy) * period
                for step in 0 ... SweepGeometry.steps {
                    let t = CGFloat(step) / CGFloat(SweepGeometry.steps)
                    let at = start + t * 0.85 * band
                    locations.append(NSNumber(value: Double(at / axis)))
                    colors.append(highlightColor(alpha: SweepGeometry.ease(t)))
                }
                for step in 1 ... SweepGeometry.steps {
                    let t = CGFloat(step) / CGFloat(SweepGeometry.steps)
                    let at = start + (0.85 + t * 0.15) * band
                    locations.append(NSNumber(value: Double(at / axis)))
                    colors.append(highlightColor(alpha: SweepGeometry.ease(1 - t)))
                }
            }
            locations.append(1)
            colors.append(UIColor.clear.cgColor)
            return (colors, locations)
        }

        private func highlightColor(alpha: CGFloat) -> CGColor {
            style.highlight.withAlphaComponent(style.highlight.cgColor.alpha * alpha).cgColor
        }

        private func restartShimmer() {
            shine.removeAllAnimations()
            guard style.shimmer == .shimmer, !UIAccessibility.isReduceMotionEnabled else {
                shine.isHidden = true
                return
            }
            shine.isHidden = false
            updateShine()

            let pace = SweepClock.pace(shimmerDuration: style.shimmerDuration)
            let duration = CFTimeInterval(tile * pace)
            guard duration > 0 else { return }

            let move = CABasicAnimation(keyPath: "transform.translation.x")
            move.fromValue = 0
            move.toValue = tile
            move.duration = duration
            move.repeatCount = .infinity
            move.timingFunction = CAMediaTimingFunction(name: .linear)
            move.timeOffset = phase(duration: duration, pace: pace)
            shine.add(move, forKey: "shimmer")
        }

        /// Where this bar sits in the page's one stream: further right, and lower down the slant, is further along it.
        private func phase(duration: CFTimeInterval, pace: CGFloat) -> CFTimeInterval {
            guard let window else { return 0 }
            let origin = convert(CGPoint.zero, to: window)
            let along = SweepGeometry.u(x: origin.x, y: origin.y)
            let offset = CFTimeInterval(along * pace).truncatingRemainder(dividingBy: duration)
            return duration - offset
        }
    }

#endif
