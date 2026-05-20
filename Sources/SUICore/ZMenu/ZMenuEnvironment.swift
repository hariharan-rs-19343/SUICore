#if targetEnvironment(macCatalyst)
import SwiftUI

// MARK: - Layout Change Behavior

/// Controls how the ZMenu dropdown responds when its anchor label moves.
public enum ZMenuLayoutChangeBehavior: Sendable {
    /// Dismiss the dropdown immediately when the label frame shifts.
    case dismiss
    /// Reactively reposition the dropdown to follow the label.
    case reposition
}

private struct ZMenuLayoutChangeBehaviorKey: EnvironmentKey {
    static let defaultValue: ZMenuLayoutChangeBehavior = .dismiss
}

extension EnvironmentValues {
    var zMenuLayoutChangeBehavior: ZMenuLayoutChangeBehavior {
        get { self[ZMenuLayoutChangeBehaviorKey.self] }
        set { self[ZMenuLayoutChangeBehaviorKey.self] = newValue }
    }
}

public extension View {
    /// Sets the behavior when the ZMenu label moves while the dropdown is open.
    ///
    /// - Parameter behavior: `.dismiss` (default) closes the menu;
    ///   `.reposition` slides the dropdown to follow the label.
    func zMenuLayoutChangeBehavior(_ behavior: ZMenuLayoutChangeBehavior) -> some View {
        environment(\.zMenuLayoutChangeBehavior, behavior)
    }
}

// MARK: - Dismiss Environment Key

public struct ZMenuDismissKey: EnvironmentKey {
    nonisolated(unsafe) public static var defaultValue: () -> Void = {}
}

public extension EnvironmentValues {
    var zMenuDismiss: () -> Void {
        get { self[ZMenuDismissKey.self] }
        set { self[ZMenuDismissKey.self] = newValue }
    }
}

#endif
