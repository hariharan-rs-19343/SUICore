//
//  ZHPaginationTabModifier.swift
//  SUICore
//
//  View modifier for applying ZHPaginationTabStyle via the environment.
//

import SwiftUI

public extension View {
    /// Applies a custom style to `ZHPaginationTab` and `ZHPillBar` descendants.
    ///
    /// ```swift
    /// ZHPaginationTab(selection: $tab, tabs: MyTab.allCases) { ... }
    ///     .zhPaginationTabStyle(.light)
    /// ```
    @MainActor
    func zhPaginationTabStyle(_ style: ZHPaginationTabStyle) -> some View {
        environment(\.zhPaginationTabStyle, style)
    }

    /// Overrides the collapsed (icon-only) capsule width for `ZHPillBar`.
    ///
    /// ```swift
    /// ZHPaginationTab(selection: $tab, tabs: MyTab.allCases) { ... }
    ///     .zhPaginationCollapseWidth(50)
    /// ```
    @MainActor
    func zhPaginationCollapseWidth(_ width: CGFloat) -> some View {
        environment(\.zhPaginationCollapseWidth, width)
    }
}
