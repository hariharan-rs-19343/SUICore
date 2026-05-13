#if targetEnvironment(macCatalyst)
import SwiftUI

// MARK: - Dismiss Environment Key

struct ZMenuDismissKey: EnvironmentKey {
    nonisolated(unsafe) static var defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var zMenuDismiss: () -> Void {
        get { self[ZMenuDismissKey.self] }
        set { self[ZMenuDismissKey.self] = newValue }
    }
}

#endif
