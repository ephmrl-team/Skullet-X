#if canImport(SwiftUI) && canImport(UIKit)
    import SwiftUI

    public extension SkeletonStyle {
        var baseColor: Color {
            Color(uiColor: base)
        }

        var highlightColor: Color {
            Color(uiColor: highlight)
        }

        var edgeInsets: EdgeInsets {
            EdgeInsets(
                top: insets.top,
                leading: insets.left,
                bottom: insets.bottom,
                trailing: insets.right
            )
        }
    }
#endif
