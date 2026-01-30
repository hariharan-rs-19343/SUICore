//
//  UIWindow+.swift
//  ZhareHub
//
//  Created by Hariharan R S on 23/01/25.
//

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

extension UIWindow {
    
    public static func getWindow() -> UIWindow? {
        guard let scene = UIApplication.shared.connectedScenes.first,
              let windowSceneDelegate = scene.delegate as? UIWindowSceneDelegate,
              let window = windowSceneDelegate.window
        else { return nil }
        
        return window
    }
    
    public static func getWindowScene() -> UIWindowScene? {
        return UIApplication.shared.connectedScenes.first as? UIWindowScene
    }
    
    public static func topViewController() -> UIViewController {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let root = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return UIViewController()
        }
        
        var topController = root
        
        while let presented = topController.presentedViewController {
            topController = presented
        }
        
        return topController
    }
}
#endif
