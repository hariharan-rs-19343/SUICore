//
//  ZHPaginationTabStyle.swift
//  SUICore
//
//  Visual configuration for `ZHPaginationTab` and `ZHPillBar`.
//  Animation behavior is internal and not user-configurable.
//

import SwiftUI

/// Visual style configuration for the pagination tab bar.
///
/// Customize colors, typography, and sizing. Animation curves are
/// internal to the component and cannot be changed.
///
/// Apply via environment:
/// ```swift
/// ZHPaginationTab(selection: $tab, tabs: MyTab.allCases) { ... }
///     .zhPaginationTabStyle(.dark)
/// ```
public struct ZHPaginationTabStyle: Sendable {

    // MARK: - Colors

    /// Foreground color for the active tab's label and icon.
    public var labelActiveColor: Color

    /// Foreground color for inactive tab labels and icons.
    public var labelInactiveColor: Color

    /// Fill color for the active tab's capsule background.
    public var pillActiveColor: Color

    /// Fill color for the idle (unselected) capsule background.
    public var pillIdleColor: Color

    // MARK: - Typography

    /// Font weight/style for tab labels.
    public var labelFont: Font

    /// Font size for tab labels (used for text width pre-measurement).
    public var labelFontSize: CGFloat

    /// Size of the tab icon (width and height).
    public var iconSize: CGFloat

    // MARK: - Sizing

    /// Height of each tab capsule.
    public var tabHeight: CGFloat

    /// Horizontal spacing between tab capsules.
    public var tabSpacing: CGFloat

    /// Horizontal padding inside each tab capsule.
    public var tabHorizontalPadding: CGFloat

    // MARK: - Initializer

    public init(
        labelActiveColor: Color = .white,
        labelInactiveColor: Color = Color(white: 0.45),
        pillActiveColor: Color = Color(white: 0.22),
        pillIdleColor: Color = Color(white: 0.18),
        labelFont: Font = .system(size: 14, weight: .medium),
        labelFontSize: CGFloat = 14,
        iconSize: CGFloat = 16,
        tabHeight: CGFloat = 36,
        tabSpacing: CGFloat = 6,
        tabHorizontalPadding: CGFloat = 12
    ) {
        self.labelActiveColor = labelActiveColor
        self.labelInactiveColor = labelInactiveColor
        self.pillActiveColor = pillActiveColor
        self.pillIdleColor = pillIdleColor
        self.labelFont = labelFont
        self.labelFontSize = labelFontSize
        self.iconSize = iconSize
        self.tabHeight = tabHeight
        self.tabSpacing = tabSpacing
        self.tabHorizontalPadding = tabHorizontalPadding
    }
}

// MARK: - Presets

public extension ZHPaginationTabStyle {
    /// Default dark style matching Notion's dark UI.
    static let dark = ZHPaginationTabStyle()

    /// Light style for light-mode interfaces.
    static let light = ZHPaginationTabStyle(
        labelActiveColor: ZHPaginationColor.labelActiveColor,
        labelInactiveColor: ZHPaginationColor.labelInactiveColor,
        pillActiveColor: ZHPaginationColor.pillActiveColor,
        pillIdleColor: ZHPaginationColor.pillIdleColor
    )
}

enum ZHPaginationColor {
    
    static var labelActiveColor: Color {
        #if os(macOS)
        return Color(NSColor.textColor)
        #else
        return Color(uiColor: .darkText)
        #endif
    }
    
    static var labelInactiveColor: Color {
        #if os(macOS)
        return Color(NSColor.secondaryLabelColor)
        #else
        return Color(uiColor: .secondaryLabel)
        #endif
    }
    
    static var pillActiveColor: Color {
        #if os(macOS)
        return Color(NSColor.controlAccentColor)
        #else
        return Color(uiColor: .systemGray5)
        #endif
    }
    
    static var pillIdleColor: Color {
        #if os(macOS)
        return Color(NSColor.controlBackgroundColor)
        #else
        return Color(uiColor: .systemGray6)
        #endif
    }
}

// MARK: - Environment Keys

extension EnvironmentValues {
    @Entry public var zhPaginationTabStyle: ZHPaginationTabStyle = .dark
    /// Custom collapsed width override. `nil` means use the default (iconSize + padding * 2).
    @Entry public var zhPaginationCollapseWidth: CGFloat? = nil
}
