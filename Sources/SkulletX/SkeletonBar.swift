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
                        let band = SweepClock.maxBand
                        LinearGradient(
                            colors: [.clear, style.highlightColor, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: band, height: proxy.size.height)
                        .offset(x: bandX(size: proxy.size, date: context.date))
                    }
                }
            }
        }

        private func bandX(size: CGSize, date: Date) -> CGFloat {
            let band = SweepClock.maxBand
            let pace = SweepClock.pace(shimmerDuration: style.shimmerDuration)
            let duration = max(Double(band * 2.5 * pace), 0.001)
            let loops = date.timeIntervalSinceReferenceDate / duration + phaseOffset
            let t = loops - loops.rounded(.down)
            return CGFloat(t) * (size.width + band * 2) - band
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
