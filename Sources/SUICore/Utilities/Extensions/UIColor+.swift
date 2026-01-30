//
//  UIColor+.swift
//  ZhareHub
//
//  Created by Hariharan R S on 06/11/24.
//

#if os(iOS) || os(macCatalyst)
import UIKit

public extension UIColor {
    /// Returns a UIColor that adapts based on the current user interface style (light/dark mode).
    ///
    /// - Parameters:
    ///   - dark: The color to be used in dark mode.
    ///   - light: The color to be used in light mode.
    /// - Returns: A UIColor that switches between dark and light colors based on the current interface style.
    private static func setAppearance(dark: UIColor, light: UIColor) -> UIColor {
        return UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? dark : light
        }
    }
    
    /// A convenience method that calls `setAppearance(dark:light:)` to apply dark and light colors.
    ///
    /// - Parameters:
    ///   - dark: The color to be used in dark mode.
    ///   - light: The color to be used in light mode.
    /// - Returns: A UIColor that adapts to dark/light mode.
    static func setColor(dark: UIColor, light: UIColor) -> UIColor {
        return setAppearance(dark: dark, light: light)
    }
    
    /// Initializes a Color instance from a hex string, supporting RGB (12-bit), RGB (24-bit), and ARGB (32-bit) formats.
    ///
    /// - Parameter hex: A hex string representing the color. It can include optional "#" and supports formats:
    ///   - RGB (12-bit, e.g., "123")
    ///   - RGB (24-bit, e.g., "112233")
    ///   - ARGB (32-bit, e.g., "FF112233")
    convenience init(hexString: String) {
        // Remove any non-alphanumeric characters (e.g., "#" symbols)
        let cleanedHex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        
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
        self.init(red: Double(red) / 255,
                  green: Double(green) / 255,
                  blue: Double(blue) / 255,
                  alpha: Double(opacity) / 255)
    }
}
#endif
