//
//  View+.swift
//  ZhareHub
//
//  Created by Hariharan R S on 15/11/24.
//

import SwiftUI

public extension View {
    /// Applies a custom shadow effect to the view.
    /// - Parameters:
    ///   - color: The color of the shadow. Default is `.black`.
    ///   - radius: The blur radius of the shadow. Default is `10`.
    ///   - x: The horizontal offset of the shadow. Default is `0`.
    ///   - y: The vertical offset of the shadow. Default is `0`.
    ///   - opacity: The opacity of the shadow color. Default is `0.3`.
    /// - Returns: A view modified with a shadow effect.
    func customShadow(color: Color = .black,
                      radius: CGFloat = 10,
                      x: CGFloat = 0,
                      y: CGFloat = 0,
                      opacity: Double = 0.3) -> some View {
        self.shadow(color: color.opacity(opacity), radius: radius, x: x, y: y)
    }

    #if os(iOS) || targetEnvironment(macCatalyst)
    /// Captures a snapshot of the view and returns it as a `UIImage`.
    /// - Note: This method uses `UIHostingController` to render the SwiftUI view in UIKit and captures an image using `UIGraphicsImageRenderer`.
    /// - Returns: A `UIImage` representation of the view.
    func snapshot(withSize targetSize: CGSize = CGSize(width: 400, height: 500)) -> UIImage {
        let controller = UIHostingController(rootView: self.ignoresSafeArea(.all, edges: .all))
        let targetSize = targetSize
        
        let view = controller.view
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view?.drawHierarchy(in: view!.bounds, afterScreenUpdates: true)
        }
    }
    #endif
}
