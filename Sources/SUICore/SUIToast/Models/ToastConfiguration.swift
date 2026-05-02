//
//  ToastConfiguration.swift
//  SUICore
//
//  Created by Hariharan R S on 02/05/26.
//


import SwiftUI

/// Bundle of presentation-level options for a single toast.
public struct ToastConfiguration {

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

    /// Optional haptic fired when the toast appears (iOS only).
    public var haptic: HapticFeedback?

    /// Sizing constraints applied to the toast frame.
    ///
    /// Without these the toast inherits the host scene's full width,
    /// which on Mac / Mac Catalyst yields a toast that spans the entire
    /// window. Defaults are tuned for readability across phone, pad,
    /// and Mac:
    ///
    ///   • `minWidth` keeps short toasts from looking pinched.
    ///   • `maxWidth` caps wide windows so the toast remains a card,
    ///     not a banner.
    ///   • `maxHeight` is opt-in; nil lets multi-line content breathe.
    public var minWidth: CGFloat
    public var maxWidth: CGFloat
    public var maxHeight: CGFloat?

    public enum HapticFeedback: Equatable {
        case success, warning, error
        case selection
        case impact(Intensity)

        public enum Intensity: Equatable { case light, medium, heavy }
    }

    public init(
        style: any ToastStyleProviding = ToastStyle.info,
        duration: ToastDuration = .medium,
        position: ToastPosition = .top,
        animation: ToastAnimationStyle = .spring,
        dismissOnTap: Bool = true,
        dismissOnSwipe: Bool = true,
        haptic: HapticFeedback? = nil,
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
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
    }
}
