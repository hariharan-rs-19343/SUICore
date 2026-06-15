//
//  ZHPillBar.swift
//  SUICore
//
//  Standalone pill-shaped tab bar with scroll-driven expansion.
//  Usable independently from `ZHPaginationTab` when you provide
//  your own pager and scroll progress.
//

import SwiftUI
#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit
#endif

/// A standalone horizontal pill tab bar synchronized with scroll progress.
///
/// Each tab renders as a capsule that expands to reveal its label when active,
/// with smooth icon crossfade and width-clipped text reveal during swipe.
///
/// For a complete pager + tab bar solution, use `ZHPaginationTab` instead.
///
/// ```swift
/// ZHPillBar(selection: $selectedTab, tabs: MyTab.allCases, scrollProgress: progress)
/// ```
public struct ZHPillBar<Tab: ZHPaginationTabItem>: View {
    @Binding public var selection: Tab
    public let tabs: [Tab]
    public let scrollProgress: CGFloat

    @Environment(\.zhPaginationTabStyle) private var style
    @Environment(\.zhPaginationCollapseWidth) private var customCollapseWidth

    // MARK: - Internal Constants (animation not user-configurable)

    private let springResponse: CGFloat = 0.35
    private let springDamping: CGFloat = 0.85

    /// Pre-measured label widths for accurate text-slot math.
    private let measuredTextWidths: [CGFloat]

    public init(selection: Binding<Tab>, tabs: [Tab], scrollProgress: CGFloat) {
        self._selection = selection
        self.tabs = tabs
        self.scrollProgress = scrollProgress
        #if os(iOS) || targetEnvironment(macCatalyst)
        let fontSize = ZHPaginationTabStyle.dark.labelFontSize
        let font = UIFont.systemFont(ofSize: fontSize, weight: .medium)
        self.measuredTextWidths = Tab.allCases.map { tab in
            ceil((tab.label as NSString).size(withAttributes: [.font: font]).width)
        }
        #else
        self.measuredTextWidths = Tab.allCases.map { _ in 60 }
        #endif
    }

    public var body: some View {
        HStack(spacing: style.tabSpacing) {
            ForEach(Array(tabs.enumerated()), id: \.element.id) { index, tab in
                tabCapsule(for: tab, at: index)
            }
        }
    }

    // MARK: - Tab Capsule

    @ViewBuilder
    private func tabCapsule(for tab: Tab, at index: Int) -> some View {
        let isSelected = selection == tab
        let dist = abs(scrollProgress - CGFloat(index))
        let fillProgress = max(0, 1 - dist)

        let naturalWidth = measuredTextWidths[index]
        let textScale: CGFloat = max(0.6, min(1.0, 0.6 + 0.4 * fillProgress))
        let scaledTextWidth = naturalWidth * textScale
        let textRevealWidth = max(0, scaledTextWidth * fillProgress)
        let iconTextGap: CGFloat = 6
        let textPadding = min(iconTextGap, textRevealWidth)
        let trailingPad = fillProgress * style.tabHorizontalPadding

        let collapsedWidth = customCollapseWidth ?? (style.iconSize + style.tabHorizontalPadding * 2)
        let capsuleWidth = collapsedWidth + textRevealWidth + textPadding + trailingPad

        Button {
            selection = tab
        } label: {
            HStack(spacing: 0) {
                ZStack {
                    Image(systemName: tab.symbolName)
                        .opacity(1 - fillProgress)
                    Image(systemName: tab.filledSymbolName)
                        .opacity(fillProgress)
                }
                .font(.system(size: style.iconSize, weight: .medium))
                .frame(width: style.iconSize, height: style.iconSize)

                Text(tab.label)
                    .font(style.labelFont)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .scaleEffect(textScale, anchor: .leading)
                    .frame(width: textRevealWidth, alignment: .leading)
                    .clipped()
                    .padding(.leading, textPadding)
            }
            .foregroundStyle(isSelected ? style.labelActiveColor : style.labelInactiveColor)
            .frame(width: capsuleWidth, height: style.tabHeight)
            .background {
                ZStack {
                    Capsule().fill(style.pillIdleColor)
                    Capsule().fill(style.pillActiveColor)
                        .opacity(fillProgress)
                }
            }
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.spring(response: springResponse, dampingFraction: springDamping), value: fillProgress)
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
