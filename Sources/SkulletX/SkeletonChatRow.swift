#if canImport(SwiftUI) && canImport(UIKit)
    import SwiftUI

    /// A skeleton shaped like a chat row: avatar, two lines of text, and a time.
    public struct SkeletonChatRow: View {
        public var style: SkeletonStyle
        public var phaseOffset: Double

        public init(style: SkeletonStyle = SkeletonStyle()) {
            self.style = style
            phaseOffset = 0
        }

        public var body: some View {
            HStack(spacing: style.spacing) {
                SkeletonBar(
                    width: style.avatarSize,
                    height: style.avatarSize,
                    style: style,
                    isCircular: true
                )
                .phase(phaseOffset)

                VStack(alignment: .leading, spacing: 8) {
                    SkeletonBar(height: style.titleHeight, style: style)
                        .phase(phaseOffset + 0.02)
                        .frame(maxWidth: 200, alignment: .leading)
                    SkeletonBar(height: style.subtitleHeight, style: style)
                        .phase(phaseOffset + 0.04)
                        .frame(maxWidth: 260, alignment: .leading)
                }

                Spacer(minLength: 0)

                SkeletonBar(width: 32, height: 10, style: style)
                    .phase(phaseOffset + 0.06)
            }
            .padding(style.edgeInsets)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityHidden(true)
        }

        /// Shifts this row's shimmer along the stream, 0…1 — `Double(index) * 0.06` keeps a list in one stream.
        public func phase(_ value: Double) -> SkeletonChatRow {
            var copy = self
            copy.phaseOffset = value
            return copy
        }
    }
#endif
