//
//  Color+.swift
//  ZhareHub
//
//  Created by Hariharan R S on 15/11/24.
//

import SwiftUI

public extension Color {
    
    /// Returns a Color that adapts based on the current user interface style (light/dark mode).
    ///
    /// - Parameters:
    ///   - dark: The color to be used in dark mode.
    ///   - light: The color to be used in light mode.
    /// - Returns: A Color that switches between dark and light colors based on the current interface style.
    #if os(iOS) || targetEnvironment(macCatalyst)
    static func setAppearance(dark: Color, light: Color) -> Color {
        UITraitCollection.current.userInterfaceStyle == .dark ? dark : light
    }
    #endif
    
    /// Initializes a Color instance from a hex string, supporting RGB (12-bit), RGB (24-bit), and ARGB (32-bit) formats.
    ///
    /// - Parameter hex: A hex string representing the color. It can include optional "#" and supports formats:
    ///   - RGB (12-bit, e.g., "123")
    ///   - RGB (24-bit, e.g., "112233")
    ///   - ARGB (32-bit, e.g., "FF112233")
    init(hex: String) {
        // Remove any non-alphanumeric characters (e.g., "#" symbols)
        let cleanedHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        
        // Initialize a variable to hold the hexadecimal value as an integer
        var hexValue: UInt64 = 0
        Scanner(string: cleanedHex).scanHexInt64(&hexValue)
        
        // Define default color component values
        let opacity, red, green, blue: UInt64
        
        switch cleanedHex.count {
        case 3: // RGB (12-bit format, e.g., "123" -> "112233")
            (opacity, red, green, blue) = (
                255,
                (hexValue >> 8) * 17,
                (hexValue >> 4 & 0xF) * 17,
                (hexValue & 0xF) * 17
            )
        case 6: // RGB (24-bit format, e.g., "112233")
            (opacity, red, green, blue) = (
                255,
                hexValue >> 16,
                hexValue >> 8 & 0xFF,
                hexValue & 0xFF
            )
        case 8: // ARGB (32-bit format, e.g., "FF112233")
            (opacity, red, green, blue) = (
                hexValue >> 24,
                hexValue >> 16 & 0xFF,
                hexValue >> 8 & 0xFF,
                hexValue & 0xFF
            )
        default: // Invalid hex format, defaults to a clear color/
            (opacity, red, green, blue) = (0, 0, 0, 0)
        }
        
        // Initialize the Color using normalized color components (0.0 to 1.0)
        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: Double(opacity) / 255
        )
    }
}
