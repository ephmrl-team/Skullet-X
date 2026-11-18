#if canImport(SwiftUI) && canImport(UIKit)
    import SwiftUI

    public extension SkeletonStyle {
        var baseColor: Color {
            Color(uiColor: base)
        }

        var highlightColor: Color {
            Color(uiColor: highlight)
        }
    }
#endif
