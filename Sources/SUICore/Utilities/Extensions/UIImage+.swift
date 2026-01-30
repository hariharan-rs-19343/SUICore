//
//  UIImage+.swift
//  ZhareHub
//
//  Created by Hariharan R S on 06/11/24.
//

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

extension UIImage {
    
    public static func getCurrentAppIcon() -> UIImage {
        #if targetEnvironment(macCatalyst)
        guard let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns") else {
            return UIImage()
        }
        return UIImage(contentsOfFile: iconURL.path)!
        #else
        guard let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primaryIconsDictionary = iconsDictionary["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primaryIconsDictionary["CFBundleIconFiles"] as? [String],
              let lastIcon = iconFiles.last,
              let icon = UIImage(named: lastIcon)
        else {
            return UIImage()
        }
        return icon
        #endif
    }
    
    /// Resizes an image to the specified size.
    ///
    /// - Parameters:
    ///     - size: the size we desire to resize the image to.
    ///
    /// - Returns: the resized image.
    ///
    public func downsampleImage(size: CGSize) -> UIImage? {
        return UIGraphicsImageRenderer(size: size).image { (context) in
            draw(in: CGRect(origin: .zero, size: size))
        }
        
    }
    
    public func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    public func resized(to width: CGFloat) -> UIImage {
        return UIGraphicsImageRenderer(size: CGSize(width: width, height: width)).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    
    public convenience init?(circleDiameter: CGFloat, color: UIColor) {
        
        let size = CGSize(width: circleDiameter, height: circleDiameter)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { (ctx) in
            color.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
        }
        
        guard let cgImage = image.cgImage else {
            return nil
        }
        
        self.init(cgImage: cgImage)
    }
    
    public enum JPEGQuality: CGFloat {
        case lowest  = 0.05
        case low     = 0.1
        case good    = 0.25
        case medium  = 0.5
        case high    = 0.75
        case highest = 1
    }
    
    /// Returns the data for the specified image in JPEG format.
    /// If the image object’s underlying image data has been purged, calling this function forces that data to be reloaded into memory.
    /// - returns: A data object containing the JPEG data, or nil if there was a problem generating the data. This function may return nil if the image has no data or if the underlying CGImageRef contains data in an unsupported bitmap format.
    public func jpeg(_ jpegQuality: JPEGQuality) -> Data? {
        return jpegData(compressionQuality: jpegQuality.rawValue)
    }
    
    //  UIImage+Resize
    public func compressTo(_ expectedSizeInMb: Int) -> UIImage? {
        let sizeInBytes = expectedSizeInMb * 1024 * 1024
        var compression: CGFloat = 1.0
        var imgData: Data?

        while compression > 0.0 {
            guard let data = self.jpegData(compressionQuality: compression) else { return nil }
            
            if data.count <= sizeInBytes {
                imgData = data
                break
            } else {
                compression -= 0.1
            }
        }
        
        if let imgData = imgData {
            return UIImage(data: imgData)
        }
        
        return nil
    }
    
    public static func isAssetAvailable(named: String) -> Bool {
        return UIImage(named: named) != nil
    }
}
#endif
