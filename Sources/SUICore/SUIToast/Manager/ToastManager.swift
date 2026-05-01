//
//  ToastManager.swift
//  SUICore
//
//  Created by Hariharan R S on 02/05/26.
//


import SwiftUI
import Combine

/// Observable controller that schedules toasts.
///
/// Inject one of these into the SwiftUI environment via the
/// `.toastContainer()` view modifier (which also installs the renderer)
/// or use the shared singleton for app-wide convenience.
@MainActor
public final class ToastManager: ObservableObject {

    /// App-wide singleton. You're free to ignore this and use your own
    /// instance; nothing internal depends on the singleton.
    public static let shared = ToastManager()

    /// The toast currently on screen, if any. Observed by the container.
    @Published public private(set) var currentToast: Toast?

    /// Pending toasts waiting their turn. Read-only externally.
    @Published public private(set) var pending: [Toast] = []

    private var dismissTask: Task<Void, Never>?

    public init() {}

    // MARK: - Presentation

    /// Enqueue a toast. If nothing is currently shown, it becomes visible
    /// immediately; otherwise it joins the back of the queue.
    public func show(_ toast: Toast) {
        if currentToast == nil {
            present(toast)
        } else {
            pending.append(toast)
        }
    }

    /// Convenience: build and enqueue a standard toast in one call.
    @discardableResult
    public func show(
        title: String,
        message: String? = nil,
        style: any ToastStyleProviding = ToastStyle.info,
        duration: ToastDuration = .medium,
        position: ToastPosition = .top,
        animation: ToastAnimationStyle = .spring,
        action: ToastAction? = nil
    ) -> UUID {
        let toast = Toast(
            title: title,
            message: message,
            action: action,
            configuration: ToastConfiguration(
                style: style,
                duration: duration,
                position: position,
                animation: animation
            )
        )
        show(toast)
        return toast.id
    }

    // MARK: - Dismissal

    /// Dismiss the toast currently on screen and advance the queue.
    public func dismiss() {
        dismissTask?.cancel()
        dismissTask = nil

        currentToast = nil

        // Advance to the next pending toast on the next runloop tick so the
        // out-transition has room to play before the in-transition starts.
        if let next = pending.first {
            pending.removeFirst()
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 120_000_000)
                self.present(next)
            }
        }
    }

    /// Dismiss a specific toast by id. If the id matches the currently
    /// visible toast, the queue advances; if it's still in `pending`, it
    /// is removed silently.
    public func dismiss(id: UUID) {
        if currentToast?.id == id {
            dismiss()
        } else {
            pending.removeAll { $0.id == id }
        }
    }

    /// Remove every toast — visible and pending.
    public func clearAll() {
        dismissTask?.cancel()
        dismissTask = nil
        pending.removeAll()
        currentToast = nil
    }

    // MARK: - Private

    private func present(_ toast: Toast) {
        currentToast = toast

        if let interval = toast.configuration.duration.timeInterval {
            dismissTask = Task { @MainActor [weak self] in
                let nanos = UInt64(interval * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanos)
                guard !Task.isCancelled, self?.currentToast?.id == toast.id else { return }
                self?.dismiss()
            }
        }
    }
}
