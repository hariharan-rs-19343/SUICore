//
//  ToastBuilder.swift
//  SUICore
//
//  Created by Hariharan R S on 02/05/26.
//


import SwiftUI

/// Chainable builder that produces a fully configured ``Toast``.
///
/// ```swift
/// let toast = ToastBuilder(title: "Saved")
///     .message("Your changes are safe.")
///     .style(.success)
///     .duration(.short)
///     .position(.bottom)
///     .animation(.spring)
///     .haptic(.success)
///     .action("Undo") { undo() }
///     .build()
/// ```
public struct ToastBuilder {

    private var title: String
    private var message: String?
    private var action: ToastAction?
    private var configuration: ToastConfiguration
    private var customContent: AnyToastContent?

    public init(title: String) {
        self.title = title
        self.configuration = ToastConfiguration()
    }

    // MARK: - Content

    public func message(_ message: String?) -> Self { mutating { $0.message = message } }

    public func action(
        _ title: String,
        isEnabled: Bool = true,
        dismissBehavior: ToastAction.DismissBehavior = .dismiss,
        handler: @escaping @MainActor @Sendable () -> Void
    ) -> Self {
        mutating {
            $0.action = ToastAction(
                title: title,
                isEnabled: isEnabled,
                dismissBehavior: dismissBehavior,
                handler: handler
            )
        }
    }

    /// Replace the standard layout with a fully custom body.
    ///
    /// Title, message and action set on the builder are ignored once custom
    /// content is supplied — the framework still owns queueing, animation,
    /// gestures and safe-area handling.
    public func content(_ provider: some ToastContentProviding) -> Self {
        mutating { $0.customContent = AnyToastContent(provider) }
    }

    // MARK: - Configuration

    public func style(_ style: any ToastStyleProviding) -> Self     { mutating { $0.configuration.style = style } }
    public func duration(_ duration: ToastDuration) -> Self          { mutating { $0.configuration.duration = duration } }
    public func position(_ position: ToastPosition) -> Self          { mutating { $0.configuration.position = position } }
    public func animation(_ animation: ToastAnimationStyle) -> Self  { mutating { $0.configuration.animation = animation } }
    public func dismissOnTap(_ flag: Bool) -> Self                   { mutating { $0.configuration.dismissOnTap = flag } }
    public func dismissOnSwipe(_ flag: Bool) -> Self                 { mutating { $0.configuration.dismissOnSwipe = flag } }
    public func cornerRadius(_ radius: CGFloat) -> Self              { mutating { $0.configuration.cornerRadius = radius } }
    public func haptic(_ haptic: ToastConfiguration.HapticFeedback?) -> Self {
        mutating { $0.configuration.haptic = haptic }
    }

    public func closeButton(_ visibility: ToastConfiguration.CloseButtonVisibility) -> Self {
        mutating { $0.configuration.closeButtonVisibility = visibility }
    }

    /// Override the toast's frame bounds. Pass any combination — values
    /// you don't supply keep their defaults (240 / 480 / nil).
    public func size(
        minWidth: CGFloat? = nil,
        maxWidth: CGFloat? = nil,
        maxHeight: CGFloat? = nil
    ) -> Self {
        mutating {
            if let minWidth  { $0.configuration.minWidth  = minWidth  }
            if let maxWidth  { $0.configuration.maxWidth  = maxWidth  }
            if let maxHeight { $0.configuration.maxHeight = maxHeight }
        }
    }

    // MARK: - Output

    /// Materialise the configuration into an immutable ``Toast`` instance.
    public func build() -> Toast {
        if let customContent {
            return Toast(configuration: configuration, payload: .custom(customContent))
        }
        return Toast(title: title, message: message, action: action, configuration: configuration)
    }

    // MARK: - Helper

    private func mutating(_ change: (inout Self) -> Void) -> Self {
        var copy = self
        change(&copy)
        return copy
    }
}
