//
//  ZHPaginationTab.swift
//  SUICore
//
//  A complete pagination tab component: pill tab bar + horizontal paged scroll view,
//  fully synchronized via scroll progress.
//

import SwiftUI

/// A scroll-synchronized pagination tab bar with per-tab capsule expansion.
///
/// Combines `ZHPillBar` with a horizontal paged `ScrollView`. The tab bar
/// expands/collapses capsules based on scroll position, and tapping a tab
/// jumps the pager directly (no intermediate page animation).
///
/// ```swift
/// @State private var selectedTab: MyTab = .home
///
/// ZHPaginationTab(selection: $selectedTab, tabs: MyTab.allCases) { tab in
///     switch tab {
///     case .home: HomeView()
///     case .settings: SettingsView()
///     }
/// }
/// .zhPaginationTabStyle(.dark)
/// ```
public struct ZHPaginationTab<Tab: ZHPaginationTabItem, Content: View>: View {
    @Binding public var selection: Tab
    public let tabs: [Tab]
    @ViewBuilder public let content: (Tab) -> Content

    @State private var scrolledTo: Tab?
    @State private var scrollProgress: CGFloat = 0
    @State private var displayProgress: CGFloat = 0
    @State private var isTapNavigation = false
    @State private var isTapAnimating = false

    @Environment(\.zhPaginationTabStyle) private var style

    private let springResponse: CGFloat = 0.35
    private let springDamping: CGFloat = 1.0

    public init(
        selection: Binding<Tab>,
        tabs: [Tab],
        @ViewBuilder content: @escaping (Tab) -> Content
    ) {
        self._selection = selection
        self.tabs = tabs
        self.content = content
    }

    public var body: some View {
        VStack(spacing: 0) {
            ZHPillBar(
                selection: $selection,
                tabs: tabs,
                scrollProgress: displayProgress
            )
            .padding(.vertical, 10)

            GeometryReader { geo in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(tabs, id: \.id) { tab in
                            content(tab)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .id(tab)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $scrolledTo)
                .onScrollGeometryChange(for: CGFloat.self) {
                    $0.contentOffset.x / max($0.containerSize.width, 1)
                } action: { _, progress in
                    let clamped = max(0, min(progress, CGFloat(tabs.count - 1)))
                    scrollProgress = clamped
                    if !isTapAnimating {
                        displayProgress = clamped
                    }
                }
            }
        }
        .onAppear { scrolledTo = selection }
        .onChange(of: selection) { _, newTab in
            guard scrolledTo != newTab else { return }
            isTapNavigation = true
            isTapAnimating = true
            withAnimation(.spring(response: springResponse, dampingFraction: springDamping)) {
                displayProgress = CGFloat(Tab.allCases.firstIndex(of: newTab) ?? 0)
            } completion: {
                isTapAnimating = false
            }
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                scrolledTo = newTab
            }
        }
        .onChange(of: scrolledTo) { _, item in
            guard let item, selection != item, !isTapNavigation else {
                isTapNavigation = false
                return
            }
            selection = item
        }
    }
}
