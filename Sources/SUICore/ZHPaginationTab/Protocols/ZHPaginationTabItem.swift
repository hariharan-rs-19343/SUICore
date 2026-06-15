//
//  ZHPaginationTabItem.swift
//  SUICore
//
//  A tab type conformance for use with `ZHPaginationTab` and `ZHPillBar`.
//

import SwiftUI

/// Defines the requirements for a tab that can be rendered by `ZHPaginationTab`.
///
/// Conform your tab enum to this protocol:
/// ```swift
/// enum MyTab: String, CaseIterable, Identifiable, ZHPaginationTabItem {
///     case home, settings
///     var id: Self { self }
///     var label: String { rawValue.capitalized }
///     var symbolName: String {
///         switch self {
///         case .home: "house"
///         case .settings: "gear"
///         }
///     }
/// }
/// ```
public protocol ZHPaginationTabItem: Hashable, CaseIterable, Identifiable where AllCases.Index == Int {
    /// The visible text label for this tab.
    var label: String { get }
    /// SF Symbol name for the outlined (inactive) icon.
    var symbolName: String { get }
    /// SF Symbol name for the filled (active) icon.
    var filledSymbolName: String { get }
}

public extension ZHPaginationTabItem {
    /// Default implementation: appends ".fill" to `symbolName`.
    var filledSymbolName: String { symbolName + ".fill" }
}
