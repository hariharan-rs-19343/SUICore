//
//  ZHPaginationTabItem.swift
//  SUICore
//
//  A tab type conformance for use with `ZHPaginationTab` and `ZHPillBar`.
//

import SwiftUI

/// Defines the requirements for a tab that can be rendered by `ZHPaginationTab`.
///
/// Supports both SF Symbols and asset catalog images (SVG stroke/filled variants).
///
/// **SF Symbols (default):**
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
///
/// **Asset catalog images:**
/// ```swift
/// enum MyTab: String, CaseIterable, Identifiable, ZHPaginationTabItem {
///     case home, settings
///     var id: Self { self }
///     var isSystemImage: Bool { false }
///     var label: String { rawValue.capitalized }
///     var symbolName: String {
///         switch self {
///         case .home: "ic_home_stroke"
///         case .settings: "ic_settings_stroke"
///         }
///     }
///     var filledSymbolName: String {
///         switch self {
///         case .home: "ic_home_filled"
///         case .settings: "ic_settings_filled"
///         }
///     }
/// }
/// ```
public protocol ZHPaginationTabItem: Hashable, CaseIterable, Identifiable where AllCases.Index == Int {
    /// The visible text label for this tab.
    var label: String { get }
    /// Icon name: SF Symbol name or asset catalog image name (stroke/outlined variant).
    var symbolName: String { get }
    /// Filled icon name: SF Symbol name or asset catalog image name (filled variant).
    var filledSymbolName: String { get }
    /// `true` for SF Symbols (default), `false` for asset catalog images.
    var isSystemImage: Bool { get }
}

public extension ZHPaginationTabItem {
    /// Default: appends ".fill" to `symbolName`.
    var filledSymbolName: String { symbolName + ".fill" }
    /// Default: SF Symbol.
    var isSystemImage: Bool { true }
}
