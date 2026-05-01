//
//  ToastContentProviding.swift
//  SUICore
//
//  Created by Hariharan R S on 02/05/26.
//
//
//  Contract for fully custom toast bodies.
//
//  The default presentation is a frosted-glass capsule with icon, title,
//  message and optional action button. When that doesn't fit, conform a
//  type to `ToastContentProviding` and inject it via `Toast(content:)` —
//  the manager will render your view inside the same animation/queue
//  pipeline without any changes to the surrounding system.
//


import SwiftUI

/// A type that produces the body of a toast.
///
/// Conformers are responsible only for *layout and content* — the
/// presentation pipeline (animation, queue, safe-area, dismissal gestures)
/// is provided by the framework regardless of which content view is used.
public protocol ToastContentProviding {

    /// The SwiftUI view rendered for the toast body.
    associatedtype Body: View

    /// Build the toast body.
    ///
    /// - Parameter dismiss: Closure the content can call to dismiss the
    ///   toast early. Useful for custom action buttons embedded inside a
    ///   fully bespoke layout.
    ///
    /// Called from the SwiftUI render path, which already runs on the
    /// main thread.
    @ViewBuilder
    func makeBody(dismiss: @escaping () -> Void) -> Body
}
