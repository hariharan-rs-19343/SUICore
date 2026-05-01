//
//  ToastContainerModifier.swift
//  SUICore
//
//  Created by Hariharan R S on 02/05/26.
//
//
//  Public View extension. Two entry points:
//
//   • `.toastContainer()`  — install once near the root of your scene to
//     render toasts pushed through a `ToastManager` (shared or injected).
//
//   • `.toast(isPresented:)` — local presentation, SwiftUI-style, when
//     you want a specific view to own its own toast without going
//     through the manager. Uses the same renderer.
//


import SwiftUI

// MARK: - Container modifier

private struct ToastContainerModifier: ViewModifier {
    @ObservedObject var manager: ToastManager

    func body(content: Content) -> some View {
        content.overlay(ToastContainerView(manager: manager))
    }
}

public extension View {
    /// Install the toast renderer over this view. Place this once on the
    /// root of your app or scene. All `.show(...)` calls on the supplied
    /// (or shared) manager will render here.
    ///
    /// - Parameter manager: Optional custom manager. Pass `nil` to use
    ///   the shared singleton.
    @MainActor
    func toastContainer(manager: ToastManager? = nil) -> some View {
        modifier(ToastContainerModifier(manager: manager ?? ToastManager.shared))
    }
}

// MARK: - Local toast (SwiftUI-style)

private struct LocalToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let toast: () -> Toast
    @StateObject private var localManager = ToastManager()

    func body(content: Content) -> some View {
        content
            .overlay(ToastContainerView(manager: localManager))
            .onChange(of: isPresented) { _, newValue in
                if newValue {
                    localManager.show(toast())
                } else {
                    localManager.clearAll()
                }
            }
            .onReceive(localManager.$currentToast) { current in
                // Mirror the manager's state back onto the binding so the
                // caller's `isPresented` flips back to `false` after the
                // toast auto-dismisses.
                if current == nil, isPresented {
                    isPresented = false
                }
            }
    }
}

public extension View {
    /// Locally-scoped toast presentation. Useful when a single view owns
    /// the toast and you'd rather not go through a global manager.
    func toast(isPresented: Binding<Bool>, _ toast: @escaping () -> Toast) -> some View {
        modifier(LocalToastModifier(isPresented: isPresented, toast: toast))
    }
}
