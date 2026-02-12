//
//  UIScreen+.swift
//  ZhareHub
//
//  Created by Hariharan R S on 29/11/24.
//

import SwiftUI

extension UIScreen {
    public static var screenWidth: CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return 0
        }
        return windowScene.screen.bounds.width
    }

    public static var screenHeight: CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return 0
        }
        return windowScene.screen.bounds.height
    }
}
