#if canImport(UIKit)
    import SkulletXCore
    import UIKit

    /// A skeleton shaped like a chat row: avatar, two lines of text, and a time.
    public final class SkeletonChatRowView: UIView {
        public var style = SkeletonStyle() {
            didSet { applyStyle() }
        }

        private let avatar = SkeletonBarView()
        private let title = SkeletonBarView()
        private let subtitle = SkeletonBarView()
        private let time = SkeletonBarView()

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
            let inset = style.insets
            let avatarY = (bounds.height - style.avatarSize) / 2
            avatar.frame = CGRect(x: inset.left, y: avatarY, width: style.avatarSize, height: style.avatarSize)

            let textX = inset.left + style.avatarSize + style.spacing
            let textWidth = max(bounds.width - textX - inset.right, 0)
            let timeWidth: CGFloat = 32
            title.frame = CGRect(
                x: textX,
                y: inset.top + 2,
                width: max(textWidth * 0.55 - timeWidth, 0),
                height: style.titleHeight
            )
            time.frame = CGRect(
                x: bounds.width - inset.right - timeWidth,
                y: inset.top + 4,
                width: timeWidth,
                height: 10
            )
            subtitle.frame = CGRect(
                x: textX,
                y: title.frame.maxY + 8,
                width: textWidth * 0.8,
                height: style.subtitleHeight
            )
        }

        private func setUp() {
            isUserInteractionEnabled = false
            avatar.isCircular = true
            for bar in [avatar, title, subtitle, time] {
                addSubview(bar)
            }
            applyStyle()
        }

        private func applyStyle() {
            for bar in [avatar, title, subtitle, time] {
                bar.style = style
            }
            setNeedsLayout()
        }
    }

#endif
