//
//  ToastAction.swift
//  SUICore
//
//  Created by Hariharan R S on 02/05/26.
//


/// Describes an action button rendered inside a toast.
///
/// The action is purely declarative — interaction states (highlight,
/// disabled) are handled by the toast view; this struct only carries
/// the data and the closure to invoke on tap.
public struct ToastAction {

    /// Behavior to apply after the action handler runs.
    public enum DismissBehavior {
        /// Keep the toast on screen after the action fires.
        case keep
        /// Dismiss the toast immediately when the action fires.
        case dismiss
    }

    /// Visible label of the action button.
    public let title: String

    /// Whether the action is enabled. A disabled action is rendered
    /// dimmed and is non-interactive.
    public var isEnabled: Bool

    /// What should happen to the toast after the action fires.
    public var dismissBehavior: DismissBehavior

    /// Callback executed when the user taps the action.
    public let handler: () -> Void

    public init(
        title: String,
        isEnabled: Bool = true,
        dismissBehavior: DismissBehavior = .dismiss,
        handler: @escaping () -> Void
    ) {
        self.title = title
        self.isEnabled = isEnabled
        self.dismissBehavior = dismissBehavior
        self.handler = handler
    }
}
