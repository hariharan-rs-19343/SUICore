//
//  LetterAvatar.swift
//  ZhareHub
//
//  Created by Hariharan R S on 23/12/24.
//

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

/// A `UIImageView` subclass that displays a letter avatar generated from a person's name.
///
/// Renders up to two initials on a deterministic background color derived from the name.
/// Supports circular clipping, custom sizing, font, and text color.
///
/// **Usage:**
/// ```swift
/// let avatar = LetterAvatar(name: "John Doe", size: 80)
/// stackView.addArrangedSubview(avatar)
///
/// // Update later
/// avatar.configure(with: "Jane Smith")
/// ```
public final class LetterAvatar: UIImageView {
    
    // MARK: - Configuration Constants
    
    private static let colorMinComponent: Int = 100
    private static let colorMaxComponent: Int = 214
    
    // MARK: - Properties
    
    private var avatarSize: CGFloat
    private var avatarFont: UIFont?
    private var textColor: UIColor
    private var isCircular: Bool
    
    // MARK: - Initializers
    
    /// Creates a letter avatar image view.
    /// - Parameters:
    ///   - name: The full name to extract initials from.
    ///   - size: The width and height of the avatar. Defaults to `100`.
    ///   - font: The font for the initials. Defaults to bold system font at 40% of size.
    ///   - textColor: The color of the initials. Defaults to white.
    ///   - circular: Whether to clip the avatar as a circle. Defaults to `true`.
    public init(
        name: String,
        size: CGFloat = 100,
        font: UIFont? = nil,
        textColor: UIColor = .white,
        circular: Bool = true
    ) {
        self.avatarSize = size
        self.avatarFont = font
        self.textColor = textColor
        self.isCircular = circular
        super.init(frame: CGRect(origin: .zero, size: CGSize(width: size, height: size)))
        configure(with: name)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public API
    
    /// Updates the avatar with a new name.
    /// - Parameter name: The full name to generate initials from.
    public func configure(with name: String) {
        let initials = Self.extractInitials(from: name)
        let backgroundColor = Self.deterministicColor(for: name)
        let resolvedFont = avatarFont ?? .boldSystemFont(ofSize: avatarSize * 0.4)
        let imageSize = CGSize(width: avatarSize, height: avatarSize)
        
        image = Self.renderAvatar(
            initials: initials,
            size: imageSize,
            font: resolvedFont,
            textColor: textColor,
            backgroundColor: backgroundColor
        )
        
        contentMode = .scaleAspectFill
        
        if isCircular {
            layer.cornerRadius = avatarSize / 2
            clipsToBounds = true
        }
    }
    
    // MARK: - Layout
    
    public override var intrinsicContentSize: CGSize {
        CGSize(width: avatarSize, height: avatarSize)
    }
    
    // MARK: - Rendering
    
    private static func renderAvatar(
        initials: String,
        size: CGSize,
        font: UIFont,
        textColor: UIColor,
        backgroundColor: UIColor
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            guard !initials.isEmpty else { return }
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: textColor
            ]
            
            let textSize = initials.size(withAttributes: attributes)
            let textOrigin = CGPoint(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2
            )
            
            initials.draw(at: textOrigin, withAttributes: attributes)
        }
    }
    
    // MARK: - Helpers
    
    private static func extractInitials(from name: String) -> String {
        let components = name.split(separator: " ").map(String.init)
        
        var initials = ""
        if let first = components.first?.first {
            initials.append(Character(first.uppercased()))
        }
        if components.count > 1, let last = components.last?.first {
            initials.append(Character(last.uppercased()))
        }
        
        return initials
    }
    
    private static func deterministicColor(for string: String) -> UIColor {
        srand48(string.hashValue)
        
        let range = colorMaxComponent - colorMinComponent
        let red   = CGFloat(colorMinComponent + Int(drand48() * Double(range))) / 255.0
        let green = CGFloat(colorMinComponent + Int(drand48() * Double(range))) / 255.0
        let blue  = CGFloat(colorMinComponent + Int(drand48() * Double(range))) / 255.0
        
        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
#endif
