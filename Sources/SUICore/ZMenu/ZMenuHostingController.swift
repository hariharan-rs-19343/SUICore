#if targetEnvironment(macCatalyst)
import SwiftUI
import UIKit

/// A hosting controller that adds keyboard navigation support to the menu overlay.
final class ZMenuHostingController<Content: View>: UIHostingController<Content> {
    var onEscape: (() -> Void)?
    var onArrowUp: (() -> Void)?
    var onArrowDown: (() -> Void)?
    var onReturn: (() -> Void)?

    override var canBecomeFirstResponder: Bool { true }

    override var keyCommands: [UIKeyCommand]? {
        [
            UIKeyCommand(
                action: #selector(handleEscape),
                input: UIKeyCommand.inputEscape
            ),
            UIKeyCommand(
                action: #selector(handleArrowUp),
                input: UIKeyCommand.inputUpArrow
            ),
            UIKeyCommand(
                action: #selector(handleArrowDown),
                input: UIKeyCommand.inputDownArrow
            ),
            UIKeyCommand(
                action: #selector(handleReturn),
                input: "\r"
            )
        ]
    }

    @objc private func handleEscape() {
        onEscape?()
    }

    @objc private func handleArrowUp() {
        onArrowUp?()
    }

    @objc private func handleArrowDown() {
        onArrowDown?()
    }

    @objc private func handleReturn() {
        onReturn?()
    }
}

#endif
