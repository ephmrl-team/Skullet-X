#if canImport(UIKit)
    import SkulletXCore
    import UIKit

    /// Colours and motion of a skeleton. Everything else — sizes, spacing, layout — is yours.
    public struct SkeletonStyle {
        public enum Shimmer: Equatable, Sendable {
            case shimmer
            case pulse
            case none
        }

        /// Translucent, so one grey reads on light and dark alike.
        public var base = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 1, alpha: 0.08)
                : UIColor(white: 0, alpha: 0.07)
        }

        public var highlight = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 1, alpha: 0.10)
                : UIColor(white: 1, alpha: 0.60)
        }

        public var radius: CGFloat = 6
        public var shimmer: Shimmer = .shimmer
        public var shimmerDuration: CFTimeInterval = SweepClock.shimmerSlow

        public init() {}
    }
#endif
