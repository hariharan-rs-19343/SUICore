//
//  ToastContainerModifier.swift
//  SUICore
//
//  Created by Hariharan R S on 02/05/26.
//
//
//  Public View extension. Three entry points:
//
//   • `.toastContainer()`  — install to render toasts pushed through a
//     `ToastManager` (shared, inherited, or explicit). Safe to install more
//     than once; the frontmost container is the one that draws.
//
//   • `.windowScopedToastContainer()` — install at the root of a scene that
//     should own its own queue, independent of every other window.
//
//   • `.toast(isPresented:)` — local presentation, SwiftUI-style, when
//     you want a specific view to own its own toast without going
//     through the manager. Uses the same renderer.
//


import SwiftUI

// MARK: - Container modifier

private struct ToastContainerModifier: ViewModifier {
    let explicitManager: ToastManager?
    let isActive: Bool?

    /// A manager injected by an enclosing `.toastContainer()`.
    ///
    /// SwiftUI carries the environment into sheets and covers, so a nested
    /// bare `.toastContainer()` picks up whatever the parent installed
    /// instead of silently reverting to the singleton.
    @Environment(ToastManager.self) private var inheritedManager: ToastManager?

    private var manager: ToastManager {
        explicitManager ?? inheritedManager ?? .shared
    }

    func body(content: Content) -> some View {
        content
            .overlay(ToastContainerView(manager: manager, activeOverride: isActive))
            // Applied after the overlay so both the host content and the
            // renderer resolve `@Environment(ToastManager.self)`.
            .environment(manager)
    }
}

public extension View {
    /// Install the toast renderer over this view.
    ///
    /// Install it once at the root of your scene, and again inside any
    /// presentation that needs its own — a sheet, a full-screen cover, a
    /// popover. This is not redundant: SwiftUI presents a sheet above the
    /// presenting view's hierarchy, so a root `.overlay` cannot draw over
    /// it, and a toast raised from sheet code would otherwise render behind
    /// the sheet and never be seen.
    ///
    /// When several containers observe the same manager, the frontmost one
    /// draws and the rest stand down, so a toast appears exactly once. When
    /// a sheet is dismissed mid-toast the parent container takes over and
    /// the toast finishes its countdown there.
    ///
    /// ```swift
    /// WindowGroup {
    ///     ContentView()
    ///         .toastContainer()
    ///         .sheet(isPresented: $editing) {
    ///             EditorView().toastContainer()   // wins while it is up
    ///         }
    /// }
    /// ```
    ///
    /// The manager is also injected into the environment, so any child view
    /// can reach it with `@Environment(ToastManager.self)`.
    ///
    /// - Parameters:
    ///   - manager: Optional explicit manager. Pass `nil` to inherit one
    ///     from an enclosing container, falling back to the shared singleton.
    ///   - isActive: Override the automatic election. `nil` (the default)
    ///     follows presentation depth and window activity; `false` stands
    ///     this container down; `true` keeps it eligible even when its
    ///     window reports inactive. Depth still decides among eligible
    ///     containers.
    @MainActor
    func toastContainer(manager: ToastManager? = nil, isActive: Bool? = nil) -> some View {
        modifier(ToastContainerModifier(explicitManager: manager, isActive: isActive))
    }
}

// MARK: - Window-scoped container

private struct WindowScopedToastModifier: ViewModifier {
    @State private var manager = ToastManager()

    func body(content: Content) -> some View {
        content.toastContainer(manager: manager)
    }
}

public extension View {
    /// Install a renderer backed by a manager private to this scene.
    ///
    /// Use this at the root of a `WindowGroup` whose windows should each
    /// keep their own toast queue. Election by window activity stops a
    /// background window from *drawing* another window's toast, but a single
    /// shared manager still has one queue — a toast raised from one window
    /// while another is key would appear in the key one. A per-window
    /// manager is the only way to keep them genuinely separate.
    ///
    /// ```swift
    /// WindowGroup {
    ///     ContentView().windowScopedToastContainer()
    /// }
    /// ```
    ///
    /// - Important: Code inside such a window must reach the manager through
    ///   `@Environment(ToastManager.self)`. `ToastManager.shared` is a
    ///   different instance and its toasts will not render here.
    @MainActor
    func windowScopedToastContainer() -> some View {
        modifier(WindowScopedToastModifier())
    }
}

// MARK: - Local toast (SwiftUI-style)

private struct LocalToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let toast: () -> Toast

    /// Private to this modifier, so its container is the only one registered
    /// against it and always wins the election.
    @State private var localManager = ToastManager()

    func body(content: Content) -> some View {
        content
            .overlay(ToastContainerView(manager: localManager, activeOverride: nil))
            .onAppear {
                // `onChange` alone would miss a view that appears with the
                // binding already `true`.
                if isPresented, !localManager.isPresenting { localManager.show(toast()) }
            }
            .onChange(of: isPresented) { _, newValue in
                if newValue {
                    localManager.show(toast())
                } else {
                    localManager.clearAll()
                }
            }
            .onChange(of: localManager.currentToast?.id) { _, _ in
                // Mirror the manager's state back onto the binding so the
                // caller's `isPresented` flips back to `false` after the
                // toast auto-dismisses.
                if localManager.currentToast == nil, isPresented {
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
