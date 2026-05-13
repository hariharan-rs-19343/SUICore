#if targetEnvironment(macCatalyst)
import SwiftUI
import UIKit

@MainActor
final class ZMenuCoordinator: ObservableObject {
    @Published var isPresented: Bool = false
    @Published var anchorFrame: CGRect = .zero

    private var overlayWindow: ZMenuOverlayWindow?
    private var hostingController: ZMenuHostingController<AnyView>?
    private var focusModel = ZMenuFocusModel()
    private var presentationID: UUID = UUID()

    func present<Content: View>(
        content: Content,
        style: AnyZMenuStyle,
        anchorFrame: CGRect,
        in windowScene: UIWindowScene
    ) {
        self.anchorFrame = anchorFrame
        self.isPresented = true
        self.presentationID = UUID()
        focusModel.reset()

        let dismissAction: () -> Void = { [weak self] in
            self?.dismiss()
        }

        let menuWidth = max(anchorFrame.width, 220)

        let menuPosition = ZMenuPositioning.calculate(
            anchorFrame: anchorFrame,
            menuSize: CGSize(width: menuWidth, height: 300),
            screenBounds: windowScene.screen.bounds
        )

        let overlayContent = ZMenuOverlayContent(
            content: AnyView(content),
            style: style,
            anchorFrame: anchorFrame,
            menuWidth: menuWidth,
            menuPosition: menuPosition,
            focusModel: focusModel,
            dismiss: dismissAction
        )

        let wrappedView = AnyView(
            overlayContent
                .id(presentationID)
                .environment(\.zMenuDismiss, dismissAction)
        )

        if let existingWindow = overlayWindow, let hosting = hostingController {
            hosting.rootView = wrappedView
            existingWindow.isHidden = false
            existingWindow.makeKeyAndVisible()
            hosting.becomeFirstResponder()
        } else {
            let window = ZMenuOverlayWindow(windowScene: windowScene)
            let hosting = ZMenuHostingController(rootView: wrappedView)
            hosting.view.backgroundColor = UIColor.clear

            hosting.onEscape = { [weak self] in
                self?.dismiss()
            }
            hosting.onArrowUp = { [weak self] in
                self?.focusModel.movePrevious()
            }
            hosting.onArrowDown = { [weak self] in
                self?.focusModel.moveNext()
            }
            hosting.onReturn = { [weak self] in
                self?.focusModel.selectCurrent()
            }

            window.rootViewController = hosting
            window.makeKeyAndVisible()
            hosting.becomeFirstResponder()

            overlayWindow = window
            hostingController = hosting
        }
    }

    func dismiss() {
        isPresented = false
        overlayWindow?.isHidden = true
        overlayWindow?.resignKey()
    }
}

// MARK: - Focus Model

@MainActor
final class ZMenuFocusModel: ObservableObject {
    @Published var focusedIndex: Int = -1
    var itemCount: Int = 0
    var onSelect: ((Int) -> Void)?

    func reset() {
        focusedIndex = -1
    }

    func moveNext() {
        if focusedIndex < itemCount - 1 {
            focusedIndex += 1
        } else {
            focusedIndex = 0
        }
    }

    func movePrevious() {
        if focusedIndex > 0 {
            focusedIndex -= 1
        } else {
            focusedIndex = itemCount - 1
        }
    }

    func selectCurrent() {
        guard focusedIndex >= 0 else { return }
        onSelect?(focusedIndex)
    }
}

// MARK: - Overlay Content View

private struct ZMenuOverlayContent: View {
    let content: AnyView
    let style: AnyZMenuStyle
    let anchorFrame: CGRect
    let menuWidth: CGFloat
    let menuPosition: CGPoint
    @ObservedObject var focusModel: ZMenuFocusModel
    let dismiss: () -> Void

    @State private var isVisible = false

    private static let absoluteMaxHeight: CGFloat = 320

    private func maxMenuHeight(in geometry: GeometryProxy) -> CGFloat {
        let screenHeight = geometry.size.height
        let spaceBelow = screenHeight - menuPosition.y - 16
        let spaceAbove = menuPosition.y - 16
        let availableSpace = max(spaceBelow, spaceAbove)
        return min(availableSpace, Self.absoluteMaxHeight)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.15)) {
                            isVisible = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            dismiss()
                        }
                    }

                style.makeContent(configuration: ZMenuStyleConfiguration(
                    label: AnyView(EmptyView()),
                    content: AnyView(
                        ScrollView(.vertical, showsIndicators: true) {
                            VStack(alignment: .leading, spacing: 0) {
                                content
                            }
                            .padding(8)
                            .frame(width: menuWidth)
                        }
                        .scrollBounceBehavior(.basedOnSize)
                        .frame(maxHeight: maxMenuHeight(in: geometry))
                        .frame(width: menuWidth)
                        .fixedSize(horizontal: false, vertical: true)
                    ),
                    isPresented: true,
                    isPressed: false
                ))
                .scaleEffect(isVisible ? 1.0 : 0.92, anchor: .top)
                .opacity(isVisible ? 1.0 : 0.0)
                .offset(x: menuPosition.x, y: menuPosition.y)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                isVisible = true
            }
        }
    }
}

#endif
