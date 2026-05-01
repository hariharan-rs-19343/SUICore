//
//  ToastContainerView.swift
//  SUICore
//
//  Created by Hariharan R S on 02/05/26.
//


import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct ToastContainerView: View {
    @ObservedObject var manager: ToastManager

    var body: some View {
        GeometryReader { _ in
            ZStack(alignment: alignment) {
                // Transparent layer so the GeometryReader takes full size
                // without intercepting hit-tests when no toast is visible.
                Color.clear

                if let toast = manager.currentToast {
                    ToastHostView(toast: toast, manager: manager)
                        .padding(.horizontal, 16)
                        .padding(toast.configuration.position == .top ? .top : .bottom, 8)
                        .transition(toast.configuration.animation.transition(for: toast.configuration.position))
                        .id(toast.id) // Force a fresh transition per toast.
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
            .animation(
                manager.currentToast?.configuration.animation.animation ?? .easeInOut,
                value: manager.currentToast?.id
            )
        }
        .allowsHitTesting(manager.currentToast != nil)
        .ignoresSafeArea(.keyboard) // Keep toasts out of the keyboard avoidance system.
    }

    private var alignment: Alignment {
        manager.currentToast?.configuration.position.alignment ?? .top
    }
}

// MARK: - Per-toast host

/// Renders a single toast and wires up gestures + haptics. Splitting this
/// out keeps `ToastContainerView` focused on layout and lets the host's
/// `onAppear` fire reliably for each new toast.
private struct ToastHostView: View {
    let toast: Toast
    let manager: ToastManager

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        body(for: toast.payload)
            .offset(y: dragOffset)
            .gesture(swipeGesture)
            .onTapGesture {
                guard toast.configuration.dismissOnTap else { return }
                manager.dismiss(id: toast.id)
            }
            .onAppear { fireHapticIfNeeded() }
            .accessibilityAddTraits(.isModal)
    }

    @ViewBuilder
    private func body(for payload: Toast.Payload) -> some View {
        switch payload {
        case .standard(let content):
            DefaultToastView(
                content: content,
                style: toast.configuration.style,
                dismiss: { manager.dismiss(id: toast.id) }
            )
        case .custom(let custom):
            custom.makeBody(dismiss: { manager.dismiss(id: toast.id) })
        }
    }

    // MARK: - Swipe-to-dismiss

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard toast.configuration.dismissOnSwipe else { return }
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
                guard toast.configuration.dismissOnSwipe else { return }
                let sign = toast.configuration.position.slideSign
                let projected = value.predictedEndTranslation.height * sign
                if projected > 60 {
                    manager.dismiss(id: toast.id)
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        dragOffset = 0
                    }
                }
            }
    }

    // MARK: - Haptics

    private func fireHapticIfNeeded() {
        guard let haptic = toast.configuration.haptic else { return }
        #if canImport(UIKit) && !os(watchOS)
        switch haptic {
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        case .impact(let intensity):
            let style: UIImpactFeedbackGenerator.FeedbackStyle = {
                switch intensity {
                case .light:  return .light
                case .medium: return .medium
                case .heavy:  return .heavy
                }
            }()
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        }
        #endif
    }
}
