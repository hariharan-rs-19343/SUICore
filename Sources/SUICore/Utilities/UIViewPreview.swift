//
//  UIViewPreview.swift
//  SUICore
//
//  Created by Hariharan R S on 11/02/26.
//

#if os(iOS) || targetEnvironment(macCatalyst)
import SwiftUI
import UIKit

/// A lightweight wrapper to use a `UIView` inside SwiftUI previews.
struct UIViewPreview<View: UIView>: UIViewRepresentable {
    let builder: () -> View
    
    init(_ builder: @escaping () -> View) {
        self.builder = builder
    }
    
    func makeUIView(context: Context) -> View { builder() }
    func updateUIView(_ uiView: View, context: Context) {}
}
#endif
