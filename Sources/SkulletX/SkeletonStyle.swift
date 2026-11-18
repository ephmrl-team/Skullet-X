#if canImport(UIKit)
    import SkulletXCore
    import UIKit

    /// Colours and metrics of a skeleton. Set what the app's theme says; the rest keeps the web defaults.
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
        public var avatarSize: CGFloat = 48
        public var spacing: CGFloat = 12
        public var insets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        public var titleHeight: CGFloat = 14
        public var subtitleHeight: CGFloat = 12

        public init() {}
    }

#endif
