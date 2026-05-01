//
//  Toast.swift
//  SUICore
//
//  Created by Hariharan R S on 02/05/26.
//


import SwiftUI

/// A single toast instance.
///
/// `Toast` is identifiable so SwiftUI can cleanly diff updates inside the
/// manager queue, and it carries an optional `id` you can pass to
/// `ToastManager.dismiss(id:)` for deterministic dismissal.
public struct Toast: Identifiable {

    /// Internal payload — kept generic so a single `Toast` type can carry
    /// either the default content or any user-provided custom content.
    enum Payload {
        case standard(StandardContent)
        case custom(AnyToastContent)
    }

    /// Default content shape (icon + title + message + optional action).
    struct StandardContent {
        var title: String
        var message: String?
        var action: ToastAction?
    }

    public let id: UUID
    public var configuration: ToastConfiguration
    let payload: Payload

    // MARK: - Built-in initialiser

    /// Build a toast with the standard frosted-glass layout.
    public init(
        id: UUID = UUID(),
        title: String,
        message: String? = nil,
        action: ToastAction? = nil,
        configuration: ToastConfiguration = ToastConfiguration()
    ) {
        self.id = id
        self.configuration = configuration
        self.payload = .standard(.init(title: title, message: message, action: action))
    }

    // MARK: - Custom-content initialiser

    /// Build a toast with a fully custom body. The framework still owns
    /// queueing, animation, dismissal gestures and safe-area handling.
    public init<Content: ToastContentProviding>(
        id: UUID = UUID(),
        configuration: ToastConfiguration = ToastConfiguration(),
        content: Content
    ) {
        self.id = id
        self.configuration = configuration
        self.payload = .custom(AnyToastContent(content))
    }
}

// MARK: - Type-erased content wrapper

/// Hides the associated `Body` type of a `ToastContentProviding`
/// implementation so different content types can coexist in the queue.
struct AnyToastContent: ToastContentProviding {
    private let _makeBody: (@escaping () -> Void) -> AnyView

    init<C: ToastContentProviding>(_ wrapped: C) {
        self._makeBody = { dismiss in AnyView(wrapped.makeBody(dismiss: dismiss)) }
    }

    func makeBody(dismiss: @escaping () -> Void) -> AnyView {
        _makeBody(dismiss)
    }
}
