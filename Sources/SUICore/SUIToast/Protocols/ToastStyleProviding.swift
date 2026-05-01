//
//  ToastStyleProviding.swift
//  SUICore
//
//  Created by Hariharan R S on 02/05/26.
//
//  Visual styling contract for a toast.
//
//  Conform a custom type to this protocol to fully control the look of a
//  toast (background material, icon, text/accent colors). The default
//  `ToastStyle` enum already provides ready-made styles (success, error,
//  warning, info) that satisfy this protocol.
//


import SwiftUI

/// A type that describes the visual appearance of a toast.
///
/// Implementations are intentionally lightweight value types so they can be
/// composed, stored, and diffed efficiently by SwiftUI.
///
/// The toast background is always Liquid Glass (iOS 26+ `.glassEffect()`).
/// Styles control colour and iconography on top of that.
public protocol ToastStyleProviding {

    /// Optional SF Symbol name displayed before the title.
    ///
    /// Returning `nil` hides the icon area entirely.
    var iconSystemName: String? { get }

    /// Tint applied to the icon.
    var iconColor: Color { get }

    /// Foreground color for title and message text.
    var textColor: Color { get }

    /// Color used for the action button and other emphasised UI.
    var accentColor: Color { get }

    /// A subtle stroke color drawn around the toast capsule.
    ///
    /// Defaults to a translucent variant of the accent color.
    var borderColor: Color { get }
}

public extension ToastStyleProviding {
    /// Default border derived from the accent color so most styles only need
    /// to specify `accentColor`.
    var borderColor: Color { accentColor.opacity(0.18) }
}
