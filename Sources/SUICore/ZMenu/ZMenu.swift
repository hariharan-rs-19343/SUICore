#if targetEnvironment(macCatalyst)
import SwiftUI
import UIKit

/// A fully customizable menu component for Mac Catalyst.
///
/// ZMenu presents a dropdown overlay above all views using a dedicated UIWindow,
/// avoiding layout collapse and zIndex issues common with SwiftUI overlays.
///
/// Usage:
/// ```swift
/// ZMenu {
///     ZMenuItem("Edit", icon: "pencil") { }
///     ZMenuItem("Delete", icon: "trash", role: .destructive) { }
///     Divider()
///     ZMenuItem("Settings", icon: "gear") { }
/// } label: {
///     Image(systemName: "ellipsis.circle")
/// }
/// .zMenuStyle(MyCustomStyle())
/// ```
public struct ZMenu<MenuContent: View, Label: View>: View {
    private let content: MenuContent
    private let label: Label
    private var externalBinding: Binding<Bool>?

    @State private var internalIsPresented = false
    @State private var anchorFrame: CGRect = .zero
    @StateObject private var coordinator = ZMenuCoordinator()
    @Environment(\.zMenuStyle) private var style

    /// Creates a ZMenu with internally managed presentation state.
    public init(
        @ViewBuilder content: () -> MenuContent,
        @ViewBuilder label: () -> Label
    ) {
        self.content = content()
        self.label = label()
        self.externalBinding = nil
    }

    /// Creates a ZMenu with externally controlled presentation state.
    public init(
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> MenuContent,
        @ViewBuilder label: () -> Label
    ) {
        self.content = content()
        self.label = label()
        self.externalBinding = isPresented
    }

    private var isPresented: Bool {
        get { externalBinding?.wrappedValue ?? internalIsPresented }
    }

    private func setPresented(_ value: Bool) {
        if let binding = externalBinding {
            binding.wrappedValue = value
        } else {
            internalIsPresented = value
        }
    }

    @State private var isTapDown = false

    public var body: some View {
        let configuration = ZMenuStyleConfiguration(
            label: AnyView(label),
            content: AnyView(content),
            isPresented: coordinator.isPresented,
            isPressed: isTapDown
        )

        style.makeBody(configuration: configuration)
            .readFrame { frame in
                anchorFrame = frame
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        isTapDown = true
                    }
                    .onEnded { _ in
                        isTapDown = false
                        toggleMenu()
                    }
            )
            .onChange(of: internalIsPresented) { _, newValue in
                if !newValue {
                    coordinator.dismiss()
                }
            }
    }

    private func toggleMenu() {
        if coordinator.isPresented {
            coordinator.dismiss()
            setPresented(false)
        } else {
            guard let windowScene = currentWindowScene() else { return }

            let menuContent = ZMenuContentView(content: { content }, dismiss: {
                coordinator.dismiss()
                setPresented(false)
            })

            coordinator.present(
                content: menuContent,
                style: style,
                anchorFrame: anchorFrame,
                in: windowScene
            )
            setPresented(true)
        }
    }

    private func currentWindowScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
    }
}

#endif
