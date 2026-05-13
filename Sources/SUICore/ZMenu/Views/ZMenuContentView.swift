#if targetEnvironment(macCatalyst)
import SwiftUI

struct ZMenuContentView<Content: View>: View {
    let content: Content
    let dismiss: () -> Void

    init(@ViewBuilder content: () -> Content, dismiss: @escaping () -> Void) {
        self.content = content()
        self.dismiss = dismiss
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .frame(minWidth: 180)
        .environment(\.zMenuDismiss, dismiss)
    }
}

#endif
