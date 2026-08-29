//
//  UIScreen+.swift
//  ZhareHub
//
//  Created by Hariharan R S on 29/11/24.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

#if canImport(UIKit)
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
#else
extension NSScreen {
    
    @MainActor public static var screenWidth: CGFloat {
        guard let window = NSApplication.shared.windows.first else {
            return 0
        }
        
        return window.frame.width
    }
    
    @MainActor public static var screenHeight: CGFloat {
        guard let window = NSApplication.shared.windows.first else {
            return 0
        }
        
        return window.frame.height
    }
}
#endif
