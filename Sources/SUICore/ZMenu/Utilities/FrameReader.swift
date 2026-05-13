#if targetEnvironment(macCatalyst)
import SwiftUI

struct FramePreferenceKey: PreferenceKey {
    static let defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

extension View {
    /// Reads the global frame of this view and reports it via a closure.
    func readFrame(in coordinateSpace: CoordinateSpace = .global, onChange: @escaping (CGRect) -> Void) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear
                    .preference(
                        key: FramePreferenceKey.self,
                        value: geometry.frame(in: coordinateSpace)
                    )
            }
        )
        .onPreferenceChange(FramePreferenceKey.self, perform: onChange)
    }
}

#endif
