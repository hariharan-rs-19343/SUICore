//
//  ToastContainerView.swift
//  SUICore
//
//  Created by Hariharan R S on 02/05/26.
//


import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct ToastContainerView: View {
    let manager: ToastManager

    /// Caller's explicit `isActive:`. `nil` leaves the election automatic.
    let activeOverride: Bool?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Whether this container's window is the one the user is working in.
    /// `appearsActive` is the supported cross-platform spelling of this —
    /// `controlActiveState` is macOS-only and deprecated in favour of it.
    @Environment(\.appearsActive) private var appearsActive

    /// Stable identity for this container, for the lifetime of the view.
    @State private var containerID = UUID()

    /// Position and animation of the toast that was last presented.
    ///
    /// The out transition runs *after* `currentToast` has already become
    /// `nil`, so reading the live value there would snap a `.bottom` toast to
    /// the top edge and replace its curve with the fallback. Falling back to
    /// the remembered values keeps the exit matching the entrance.
    @State private var lastPosition: ToastPosition = .top
    @State private var lastAnimation: ToastAnimationStyle = .spring

    private static let horizontalInset: CGFloat = 16

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: position.alignment) {
                // Transparent layer so the ZStack takes full size. `Color` is
                // hit-testable, so this must opt out explicitly or it would
                // swallow every touch aimed at the app behind the toast.
                Color.clear
                    .allowsHitTesting(false)

                // Only the frontmost installed container draws. Without this
                // a root container and a sheet's container — both observing
                // the same manager — would render the same toast twice.
                if isActiveContainer, let toast = manager.currentToast {
                    let bounds = widthBounds(for: toast, in: proxy)

                    ToastHostView(toast: toast, manager: manager)
                        // Width/height bounds first so the toast is sized
                        // before being padded into the safe area.
                        .frame(
                            minWidth: bounds.min,
                            maxWidth: bounds.max,
                            maxHeight: toast.configuration.maxHeight
                        )
                        // `fixedSize(horizontal: false, vertical: true)`
                        // lets the toast hug content vertically while
                        // still respecting the horizontal min/max bounds.
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, Self.horizontalInset)
                        .padding(toast.configuration.position == .top ? .top : .bottom, 8)
                        .transition(animation.transition(for: position, reduceMotion: reduceMotion))
                        .id(toast.id) // Force a fresh transition per toast.
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: position.alignment)
        }
        .animation(animation.animation(reduceMotion: reduceMotion), value: manager.currentToast?.id)
        .ignoresSafeArea(.keyboard) // Keep toasts out of the keyboard avoidance system.
        .onChange(of: manager.currentToast?.id) { _, _ in
            guard let configuration = manager.currentToast?.configuration else { return }
            lastPosition  = configuration.position
            lastAnimation = configuration.animation
        }
        .onAppear { syncRegistration(installing: true) }
        .onDisappear { manager.unregister(container: containerID) }
        .onChange(of: appearsActive)  { _, _ in syncRegistration(installing: false) }
        .onChange(of: activeOverride) { _, _ in syncRegistration(installing: false) }
    }

    /// Whether this container won the election for the manager it observes.
    private var isActiveContainer: Bool {
        manager.activeContainerID == containerID
    }

    /// Push this container's eligibility into the manager.
    ///
    /// Handover between layers is deliberately unanimated: the toast itself
    /// hasn't changed, only which layer is drawing it, so animating would
    /// read as a second toast flying in rather than the same one staying put.
    /// The container's own `.animation(_:value:)` is keyed on the toast id
    /// and so already ignores this, but an ambient animation running
    /// elsewhere would otherwise be picked up.
    private func syncRegistration(installing: Bool) {
        var transaction = Transaction()
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            if installing {
                manager.register(
                    container: containerID,
                    windowIsActive: appearsActive,
                    override: activeOverride
                )
            } else {
                manager.updateContainer(
                    containerID,
                    windowIsActive: appearsActive,
                    override: activeOverride
                )
            }
        }
    }

    /// Live values while a toast is on screen, remembered values while one
    /// is animating out.
    private var position: ToastPosition {
        manager.currentToast?.configuration.position ?? lastPosition
    }

    private var animation: ToastAnimationStyle {
        manager.currentToast?.configuration.animation ?? lastAnimation
    }

    /// Clamp the configured bounds to the space actually available, so a
    /// narrow Mac window or a compact split view can't overflow.
    private func widthBounds(for toast: Toast, in proxy: GeometryProxy) -> (min: CGFloat, max: CGFloat) {
        let available = proxy.size.width - Self.horizontalInset * 2
        guard available > 0 else {
            return (toast.configuration.minWidth, toast.configuration.maxWidth)
        }
        return (
            min(toast.configuration.minWidth, available),
            min(toast.configuration.maxWidth, available)
        )
    }
}

// MARK: - Per-toast host

/// Renders a single toast and wires up gestures, hover and haptics.
/// Splitting this out keeps `ToastContainerView` focused on layout and lets
/// the host's `onAppear` fire reliably for each new toast.
private struct ToastHostView: View {
    let toast: Toast
    let manager: ToastManager

    @State private var dragOffset: CGFloat = 0

    private var isDismissible: Bool {
        toast.configuration.dismissOnTap || toast.configuration.dismissOnSwipe
    }

    var body: some View {
        body(for: toast.payload)
            .offset(y: dragOffset)
            .gesture(swipeGesture, isEnabled: toast.configuration.dismissOnSwipe)
            .onTapGesture {
                guard toast.configuration.dismissOnTap else { return }
                dismiss()
            }
            // Pointer platforms expect the countdown to hold while the user
            // is reading (or reaching for the action button).
            .onHover { hovering in
                if hovering { manager.pauseAutoDismiss() } else { manager.resumeAutoDismiss() }
            }
            .background { escapeKeyDismissal }
            .onAppear {
                fireHapticIfNeeded()
                announceIfNeeded()
            }
    }

    @ViewBuilder
    private func body(for payload: Toast.Payload) -> some View {
        switch payload {
        case .standard(let content):
            DefaultToastView(
                content: content,
                configuration: toast.configuration,
                dismiss: dismiss
            )
        case .custom(let custom):
            custom.makeBody(dismiss: dismiss)
        }
    }

    private func dismiss() {
        manager.dismiss(id: toast.id)
    }

    // MARK: - Keyboard

    /// Escape dismisses, but only for `.persistent` toasts — those are the
    /// ones that need a manual out. Claiming the cancel action for a toast
    /// that disappears on its own would hijack Escape from the host app.
    @ViewBuilder
    private var escapeKeyDismissal: some View {
        if isDismissible, toast.configuration.duration == .persistent {
            Button("", action: dismiss)
                .keyboardShortcut(.cancelAction)
                .opacity(0)
                .frame(width: 0, height: 0)
                .accessibilityHidden(true)
        }
    }

    // MARK: - Swipe-to-dismiss

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                // Hold the countdown for as long as the user is interacting.
                manager.pauseAutoDismiss()

                let sign = toast.configuration.position.slideSign
                // Allow movement only in the natural direction (up for top, down for bottom).
                if value.translation.height * sign > 0 {
                    dragOffset = value.translation.height
                } else {
                    // Slight rubber-banding for a more tactile feel.
                    dragOffset = value.translation.height / 4
                }
            }
            .onEnded { value in
                let sign = toast.configuration.position.slideSign
                let projected = value.predictedEndTranslation.height * sign
                if projected > 60 {
                    dismiss()
                } else {
                    manager.resumeAutoDismiss()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        dragOffset = 0
                    }
                }
            }
    }

    // MARK: - Accessibility

    /// A toast is a passive status change, so VoiceOver never moves focus to
    /// it — without an announcement it is simply never spoken.
    private func announceIfNeeded() {
        guard case .standard(let content) = toast.payload else { return }

        var spoken = content.title
        if let message = content.message, !message.isEmpty {
            spoken += ". " + message
        }
        AccessibilityNotification.Announcement(spoken).post()
    }

    // MARK: - Haptics

    private func fireHapticIfNeeded() {
        guard let haptic = toast.configuration.haptic else { return }

        #if canImport(UIKit) && !os(watchOS)
        switch haptic {
        case .success, .warning, .error:
            let type: UINotificationFeedbackGenerator.FeedbackType = switch haptic {
            case .success: .success
            case .warning: .warning
            default:       .error
            }
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(type)

        case .selection:
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()

        case .impact(let intensity):
            let style: UIImpactFeedbackGenerator.FeedbackStyle = switch intensity {
            case .light:  .light
            case .medium: .medium
            case .heavy:  .heavy
            }
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.prepare()
            generator.impactOccurred()
        }

        #elseif canImport(AppKit)
        // AppKit exposes only three trackpad patterns; map the semantic
        // cases onto the closest match rather than dropping them silently.
        let pattern: NSHapticFeedbackManager.FeedbackPattern = switch haptic {
        case .success, .warning, .error: .levelChange
        case .selection:                 .alignment
        case .impact:                    .generic
        }
        NSHapticFeedbackManager.defaultPerformer.perform(pattern, performanceTime: .now)
        #endif
    }
}
