#if targetEnvironment(macCatalyst)
import SwiftUI

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
