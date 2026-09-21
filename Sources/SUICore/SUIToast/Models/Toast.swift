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
/// manager queue, and it carries an `id` you can pass to
/// ``ToastManager/dismiss(id:)`` for deterministic dismissal.
///
/// The type is `Sendable`, so a toast may be constructed off the main actor
/// and handed to `await manager.show(_:)`.
public struct Toast: Identifiable, Sendable {

    /// Internal payload — kept generic so a single `Toast` type can carry
    /// either the default content or any user-provided custom content.
    enum Payload: Sendable {
        case standard(StandardContent)
        case custom(AnyToastContent)
    }

    /// Default content shape (icon + title + message + optional action).
    struct StandardContent: Sendable {
        var title: String
        var message: String?
        var action: ToastAction?
    }

    public let id: UUID
    public var configuration: ToastConfiguration
    let payload: Payload

    // MARK: - Built-in initialiser

    /// Build a toast with the standard glass layout.
    public init(
        id: UUID = UUID(),
        title: String,
        message: String? = nil,
        action: ToastAction? = nil,
        configuration: ToastConfiguration = ToastConfiguration()
    ) {
        self.init(
            id: id,
            configuration: configuration,
            payload: .standard(.init(title: title, message: message, action: action))
        )
    }

    // MARK: - Custom-content initialiser

    /// Build a toast with a fully custom body. The framework still owns
    /// queueing, animation, dismissal gestures and safe-area handling.
    public init<Content: ToastContentProviding>(
        id: UUID = UUID(),
        configuration: ToastConfiguration = ToastConfiguration(),
        content: Content
    ) {
        self.init(id: id, configuration: configuration, payload: .custom(AnyToastContent(content)))
    }

    /// Designated internal initialiser. Lets ``ToastBuilder`` hand over an
    /// already-erased payload without wrapping it a second time.
    init(id: UUID = UUID(), configuration: ToastConfiguration, payload: Payload) {
        self.id = id
        self.configuration = configuration
        self.payload = payload
    }

    /// Identity used by ``ToastManager/QueuePolicy/dropIfDuplicate``.
    ///
    /// `nil` for custom content, which the manager cannot compare.
    var duplicateKey: String? {
        guard case .standard(let content) = payload else { return nil }
        return content.title + "\u{1}" + (content.message ?? "")
    }
}

// MARK: - Type-erased content wrapper

/// Hides the associated `Body` type of a `ToastContentProviding`
/// implementation so different content types can coexist in the queue.
struct AnyToastContent: ToastContentProviding {
    private let _makeBody: @MainActor @Sendable (@escaping @MainActor @Sendable () -> Void) -> AnyView

    init<C: ToastContentProviding>(_ wrapped: C) {
        self._makeBody = { dismiss in AnyView(wrapped.makeBody(dismiss: dismiss)) }
    }

    @MainActor
    func makeBody(dismiss: @escaping @MainActor @Sendable () -> Void) -> AnyView {
        _makeBody(dismiss)
    }
}
