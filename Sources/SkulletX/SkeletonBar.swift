#if canImport(SwiftUI) && canImport(UIKit)
    import SkulletXCore
    import SwiftUI

    /// One bar of a skeleton: a rounded base with the page's shimmer crossing it.
    public struct SkeletonBar: View {
        public var style = SkeletonStyle()
        public var width: CGFloat?
        public var height: CGFloat
        public var isCircular: Bool
        /// 0…1: shifts this bar's shimmer along the stream, so a list reads as one sweep.
        public var phaseOffset: Double

        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @State private var pulsing = false

        public init(
            width: CGFloat? = nil,
            height: CGFloat = 12,
            style: SkeletonStyle = SkeletonStyle(),
            isCircular: Bool = false
        ) {
            self.width = width
            self.height = height
            self.style = style
            self.isCircular = isCircular
            phaseOffset = 0
        }

        public var body: some View {
            shape
                .fill(style.baseColor)
                .frame(width: width, height: height)
                .overlay { shimmer }
                .clipShape(shape)
                .opacity(pulsing ? 0.45 : 1)
                .accessibilityHidden(true)
                .onAppear { startPulse() }
                .onChange(of: style.shimmer) { _, _ in startPulse() }
        }

        /// Shifts this bar's shimmer along the stream, 0…1, so a list reads as one sweep.
        public func phase(_ value: Double) -> SkeletonBar {
            var copy = self
            copy.phaseOffset = value
            return copy
        }

        private var shape: RoundedRectangle {
            RoundedRectangle(cornerRadius: isCircular ? height / 2 : style.radius, style: .continuous)
        }

        @ViewBuilder
        private var shimmer: some View {
            if style.shimmer == .shimmer, !reduceMotion {
                TimelineView(.animation(minimumInterval: 1 / 60)) { context in
                    GeometryReader { proxy in
                        let period = SweepClock.maxBand * 2.5 / SweepGeometry.cosSlant
                        let margin = proxy.size.height * SweepGeometry.tanSlant
                        let width = SweepClock.maxBand / SweepGeometry.cosSlant + 2 * margin
                        let points = SweepGeometry.gradientPoints(for: CGSize(width: width, height: proxy.size.height))
                        let count = Int(ceil((proxy.size.width + width) / period)) + 2
                        ForEach(0 ..< count, id: \.self) { index in
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0),
                                    .init(color: .clear, location: margin / (width + margin)),
                                    .init(color: style.highlightColor, location: 0.5),
                                    .init(color: .clear, location: width / (width + margin)),
                                    .init(color: .clear, location: 1),
                                ],
                                startPoint: UnitPoint(x: points.start.x, y: points.start.y),
                                endPoint: UnitPoint(x: points.end.x, y: points.end.y)
                            )
                            .frame(width: width, height: proxy.size.height)
                            .offset(x: bandX(origin: proxy.frame(in: .global).origin, date: context.date)
                                - (width + margin) / 2 + CGFloat(index - 1) * period)
                        }
                    }
                }
            }
        }

        private func bandX(origin: CGPoint, date: Date) -> CGFloat {
            let period = SweepClock.maxBand * 2.5 / SweepGeometry.cosSlant
            let pace = SweepClock.pace(shimmerDuration: style.shimmerDuration)
            guard pace > 0 else { return 0 }
            let duration = Double(period * pace)
            let time = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: duration)
            let position = CGFloat(time) / pace - SweepGeometry.u(origin) + CGFloat(phaseOffset) * period
            return position - floor(position / period) * period
        }

        private func startPulse() {
            guard style.shimmer == .pulse, !reduceMotion else {
                pulsing = false
                return
            }
            withAnimation(
                .easeInOut(duration: style.shimmerDuration * 0.6).repeatForever(autoreverses: true)
            ) {
                pulsing = true
            }
        }
    }
#endif
