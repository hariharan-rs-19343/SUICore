//
//  ToastConfiguration.swift
//  SUICore
//
//  Created by Hariharan R S on 02/05/26.
//


import SwiftUI

/// Bundle of presentation-level options for a single toast.
public struct ToastConfiguration: Sendable {

    /// Visual style. Defaults to `.info`.
    public var style: any ToastStyleProviding

    /// How long the toast stays on screen.
    public var duration: ToastDuration

    /// Where the toast appears within the safe area.
    public var position: ToastPosition

    /// Animation used when entering/leaving.
    public var animation: ToastAnimationStyle

    /// Whether tapping the toast dismisses it.
    public var dismissOnTap: Bool

    /// Whether swiping the toast dismisses it.
    public var dismissOnSwipe: Bool

    /// Optional haptic fired when the toast appears.
    ///
    /// Mapped to `UIFeedbackGenerator` on iOS and to
    /// `NSHapticFeedbackManager` on macOS; silently ignored on platforms
    /// with no haptic hardware.
    public var haptic: HapticFeedback?

    /// Corner radius of the glass background.
    ///
    /// The default matches the rest of SUICore's glass surfaces. A capsule
    /// look is *not* the default because it distorts multi-line content.
    public var cornerRadius: CGFloat

    /// Whether the default layout draws an explicit close button.
    public var closeButtonVisibility: CloseButtonVisibility

    /// Sizing constraints applied to the toast frame.
    ///
    /// Without these the toast inherits the host scene's full width,
    /// which on Mac yields a toast that spans the entire window. Defaults
    /// are tuned for readability across phone, pad, and Mac:
    ///
    ///   • `minWidth` keeps short toasts from looking pinched.
    ///   • `maxWidth` caps wide windows so the toast remains a card,
    ///     not a banner.
    ///   • `maxHeight` is opt-in; nil lets multi-line content breathe.
    ///
    /// Both widths are additionally clamped to the space actually available,
    /// so a narrow window or a compact split view can never overflow.
    public var minWidth: CGFloat
    public var maxWidth: CGFloat
    public var maxHeight: CGFloat?

    public enum HapticFeedback: Equatable, Sendable {
        case success, warning, error
        case selection
        case impact(Intensity)

        public enum Intensity: Equatable, Sendable { case light, medium, heavy }
    }

    /// Controls the explicit close affordance in the default layout.
    public enum CloseButtonVisibility: Equatable, Sendable {
        /// Shown on macOS (where swipe-to-dismiss is awkward with a mouse)
        /// and for `.persistent` toasts on every platform.
        case automatic
        case visible
        case hidden
    }

    public init(
        style: any ToastStyleProviding = ToastStyle.info,
        duration: ToastDuration = .medium,
        position: ToastPosition = .top,
        animation: ToastAnimationStyle = .spring,
        dismissOnTap: Bool = true,
        dismissOnSwipe: Bool = true,
        haptic: HapticFeedback? = nil,
        cornerRadius: CGFloat = 16,
        closeButtonVisibility: CloseButtonVisibility = .automatic,
        minWidth: CGFloat = 240,
        maxWidth: CGFloat = 480,
        maxHeight: CGFloat? = nil
    ) {
        self.style = style
        self.duration = duration
        self.position = position
        self.animation = animation
        self.dismissOnTap = dismissOnTap
        self.dismissOnSwipe = dismissOnSwipe
        self.haptic = haptic
        self.cornerRadius = cornerRadius
        self.closeButtonVisibility = closeButtonVisibility
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
    }
}
