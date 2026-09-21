//
//  ToastManager.swift
//  SUICore
//
//  Created by Hariharan R S on 02/05/26.
//


import SwiftUI
import Observation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Observable controller that schedules toasts.
///
/// Install the renderer with the `.toastContainer()` view modifier, which
/// also injects the manager into the SwiftUI environment so child views can
/// reach it with `@Environment(ToastManager.self)`. A shared singleton is
/// provided for app-wide convenience; nothing internal depends on it.
@MainActor
@Observable
public final class ToastManager {

    /// What to do with a new toast while another one is already on screen.
    public enum QueuePolicy: Equatable, Sendable {
        /// Queue it behind the visible toast (default).
        case enqueue
        /// Replace the visible toast immediately.
        case replaceCurrent
        /// Queue it, unless a toast with the same title and message is
        /// already visible or waiting. Custom-content toasts are never
        /// considered duplicates because their bodies can't be compared.
        case dropIfDuplicate
    }

    /// App-wide singleton. You're free to ignore this and use your own
    /// instance; nothing internal depends on the singleton.
    public static let shared = ToastManager()

    /// The toast currently on screen, if any. Observed by the container.
    public private(set) var currentToast: Toast?

    /// Pending toasts waiting their turn. Read-only externally.
    ///
    /// A toast stays in this array right up until it is presented, so
    /// ``dismiss(id:)`` can always cancel one that has not appeared yet.
    public private(set) var pending: [Toast] = []

    /// How many toasts may wait behind the visible one. When the queue is
    /// full the *oldest* pending toast is dropped, on the assumption that
    /// the newest status is the one worth showing.
    public var maxQueueDepth: Int

    /// How ``show(_:)`` behaves when a toast is already visible.
    public var queuePolicy: QueuePolicy

    /// Whether a toast is on screen right now.
    public var isPresenting: Bool { currentToast != nil }

    /// Multiplier applied to auto-dismiss durations while VoiceOver runs —
    /// the stock 1.5 s is not enough for a screen reader to speak a toast.
    public var voiceOverDurationMultiplier: Double = 2.5

    /// The container currently entitled to render this manager's toast.
    ///
    /// A scene can install more than one renderer — typically one at the
    /// root and another inside a sheet, because a sheet is presented above
    /// the presenting hierarchy and a root `.overlay` cannot draw over it.
    /// Every container observing this manager would otherwise draw the same
    /// toast at once, so exactly one is elected here. See ``register(container:windowIsActive:override:)``.
    public private(set) var activeContainerID: UUID?

    /// Installed containers in installation order; the last eligible one wins.
    private var containers: [ContainerRegistration] = []

    /// Gap between one toast leaving and the next arriving, so the out
    /// transition has room to play before the in transition starts.
    private static let queueGap: Duration = .milliseconds(120)

    private var dismissTask: Task<Void, Never>?
    private var queueTask: Task<Void, Never>?

    /// Auto-dismiss bookkeeping, kept so the countdown can be paused and
    /// resumed (pointer hover, active drag) without losing elapsed time.
    private var timerStart: ContinuousClock.Instant?
    private var timerRemaining: TimeInterval?
    private var isPaused = false

    public init(maxQueueDepth: Int = 8, queuePolicy: QueuePolicy = .enqueue) {
        self.maxQueueDepth = max(0, maxQueueDepth)
        self.queuePolicy = queuePolicy
    }

    // MARK: - Presentation

    /// Enqueue a toast. If nothing is currently shown, it becomes visible
    /// immediately; otherwise ``queuePolicy`` decides what happens.
    ///
    /// - Returns: The toast's id, for later use with ``dismiss(id:)``.
    @discardableResult
    public func show(_ toast: Toast) -> UUID {
        // A queued advance must never outlive an explicit show, or it would
        // overwrite this toast 120 ms after it appeared.
        cancelQueueAdvance()

        if queuePolicy == .dropIfDuplicate, isDuplicate(toast) {
            return toast.id
        }

        if currentToast == nil || queuePolicy == .replaceCurrent {
            present(toast)
        } else {
            enqueue(toast)
        }
        return toast.id
    }

    /// Convenience: build and enqueue a standard toast in one call.
    @discardableResult
    public func show(
        title: String,
        message: String? = nil,
        configuration: ToastConfiguration = ToastConfiguration(),
        action: ToastAction? = nil
    ) -> UUID {
        show(Toast(title: title, message: message, action: action, configuration: configuration))
    }

    // MARK: - Dismissal

    /// Dismiss the toast currently on screen and advance the queue.
    public func dismiss() {
        cancelDismissTimer()
        currentToast = nil
        scheduleQueueAdvance()
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

    /// Remove every toast — visible and pending — and cancel all timers.
    public func clearAll() {
        cancelDismissTimer()
        cancelQueueAdvance()
        pending.removeAll()
        currentToast = nil
    }

    // MARK: - Auto-dismiss control

    /// Hold the auto-dismiss countdown. Used while the pointer hovers the
    /// toast or a drag is in progress. Safe to call repeatedly.
    public func pauseAutoDismiss() {
        guard !isPaused, currentToast != nil,
              let start = timerStart, let remaining = timerRemaining
        else { return }

        isPaused = true
        dismissTask?.cancel()
        dismissTask = nil

        let elapsed = (ContinuousClock.now - start).seconds
        timerRemaining = max(0, remaining - elapsed)
        timerStart = nil
    }

    /// Resume a countdown held by ``pauseAutoDismiss()``. Safe to call
    /// when nothing is paused.
    public func resumeAutoDismiss() {
        guard isPaused else { return }
        isPaused = false

        guard let toast = currentToast, let remaining = timerRemaining else { return }
        runDismissTimer(for: toast, interval: remaining)
    }

    // MARK: - Container arbitration

    /// Install a renderer. Called by ``ToastContainerView`` on appear.
    ///
    /// Registration is **idempotent by id**: re-registering a container that
    /// is already known refreshes its flags but does *not* move it to the
    /// front of the queue. SwiftUI fires `onAppear` again for views that come
    /// back into play — a tab switch or a navigation pop behind a presented
    /// sheet — and without this the root container would leapfrog the sheet
    /// and steal the toast back mid-presentation.
    ///
    /// - Parameters:
    ///   - id: Stable identity of the container, held in its `@State`.
    ///   - windowIsActive: The container's `\.appearsActive` environment value.
    ///   - override: Caller's explicit `isActive:`; `nil` means automatic.
    func register(container id: UUID, windowIsActive: Bool, override: Bool?) {
        if let index = containers.firstIndex(where: { $0.id == id }) {
            containers[index].windowIsActive = windowIsActive
            containers[index].override = override
        } else {
            containers.append(
                ContainerRegistration(id: id, windowIsActive: windowIsActive, override: override)
            )
        }
        recomputeActiveContainer()
    }

    /// Refresh a registered container's eligibility inputs.
    func updateContainer(_ id: UUID, windowIsActive: Bool, override: Bool?) {
        guard let index = containers.firstIndex(where: { $0.id == id }) else { return }
        containers[index].windowIsActive = windowIsActive
        containers[index].override = override
        recomputeActiveContainer()
    }

    /// Remove a renderer. Called on disappear; this is what hands a toast
    /// back to the parent container when a sheet is dismissed.
    func unregister(container id: UUID) {
        containers.removeAll { $0.id == id }
        recomputeActiveContainer()
    }

    /// Drop every container registration.
    ///
    /// An escape hatch: if a presentation layer is torn down without SwiftUI
    /// calling `onDisappear`, its registration would linger and hold the
    /// toast layer against a container that is actually on screen. Callers
    /// should not need this, but recovering beats relaunching.
    public func resetContainers() {
        containers.removeAll()
        recomputeActiveContainer()
    }

    /// Elect the frontmost eligible container.
    ///
    /// Last-registered wins, which maps onto presentation depth: the root
    /// appears first, a sheet second, a sheet-on-sheet third. The fallback to
    /// the last container regardless of eligibility is deliberate — in hosts
    /// where `appearsActive` reports oddly (previews, test harnesses, an app
    /// that never becomes key) it keeps toasts rendering somewhere instead of
    /// silently swallowing every one of them.
    private func recomputeActiveContainer() {
        activeContainerID = containers.last(where: \.isEligible)?.id ?? containers.last?.id
    }

    /// One installed renderer.
    private struct ContainerRegistration {
        let id: UUID
        var windowIsActive: Bool
        /// Caller's explicit `isActive:`. `nil` defers to the window.
        var override: Bool?

        var isEligible: Bool { override ?? windowIsActive }
    }

    // MARK: - Queue

    private func enqueue(_ toast: Toast) {
        guard maxQueueDepth > 0 else { return }
        if pending.count >= maxQueueDepth {
            pending.removeFirst(pending.count - maxQueueDepth + 1)
        }
        pending.append(toast)
    }

    private func isDuplicate(_ toast: Toast) -> Bool {
        guard let key = toast.duplicateKey else { return false }
        if currentToast?.duplicateKey == key { return true }
        return pending.contains { $0.duplicateKey == key }
    }

    /// Advance to the next pending toast after a short gap.
    ///
    /// The toast is deliberately left in `pending` until the moment it is
    /// presented, and the task handle is retained, so `clearAll()` and
    /// `dismiss(id:)` can both still cancel it mid-flight.
    private func scheduleQueueAdvance() {
        cancelQueueAdvance()
        guard !pending.isEmpty else { return }

        queueTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: Self.queueGap)
            guard !Task.isCancelled, let self,
                  self.currentToast == nil, !self.pending.isEmpty
            else { return }

            self.queueTask = nil
            self.present(self.pending.removeFirst())
        }
    }

    private func cancelQueueAdvance() {
        queueTask?.cancel()
        queueTask = nil
    }

    // MARK: - Private

    private func present(_ toast: Toast) {
        cancelDismissTimer()
        cancelQueueAdvance()

        currentToast = toast

        guard let interval = resolvedInterval(for: toast) else { return }
        timerRemaining = interval
        isPaused = false
        runDismissTimer(for: toast, interval: interval)
    }

    private func runDismissTimer(for toast: Toast, interval: TimeInterval) {
        timerStart = .now
        timerRemaining = interval

        dismissTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(interval))
            guard !Task.isCancelled, let self, self.currentToast?.id == toast.id else { return }
            self.dismissTask = nil
            self.dismiss()
        }
    }

    private func cancelDismissTimer() {
        dismissTask?.cancel()
        dismissTask = nil
        timerStart = nil
        timerRemaining = nil
        isPaused = false
    }

    /// Auto-dismiss interval for a toast, stretched while VoiceOver runs.
    private func resolvedInterval(for toast: Toast) -> TimeInterval? {
        guard let base = toast.configuration.duration.timeInterval else { return nil }
        guard Self.isVoiceOverRunning else { return base }
        return min(base * voiceOverDurationMultiplier, ToastDuration.maximumInterval)
    }

    private static var isVoiceOverRunning: Bool {
        #if canImport(UIKit)
        return UIAccessibility.isVoiceOverRunning
        #elseif canImport(AppKit)
        return NSWorkspace.shared.isVoiceOverEnabled
        #else
        return false
        #endif
    }
}

// MARK: - Duration bridging

private extension Duration {
    /// `Duration` as seconds, for the pause/resume arithmetic.
    var seconds: TimeInterval {
        let parts = components
        return TimeInterval(parts.seconds) + TimeInterval(parts.attoseconds) / 1e18
    }
}
