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
        haptic: HapticFeedback? = nil
    ) {
        self.style = style
        self.duration = duration
        self.position = position
        self.animation = animation
        self.dismissOnTap = dismissOnTap
        self.dismissOnSwipe = dismissOnSwipe
        self.haptic = haptic
    }
}
