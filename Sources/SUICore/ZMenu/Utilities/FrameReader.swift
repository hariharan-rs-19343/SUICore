#if targetEnvironment(macCatalyst)
import SwiftUI

extension View {
    /// Reads the global frame of this view and reports it via a closure.
    func readFrame(in coordinateSpace: CoordinateSpace = .global, onChange: @escaping (CGRect) -> Void) -> some View {
        onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: coordinateSpace)
        } action: { _, newFrame in
            onChange(newFrame)
        }
    }
}

#endif
