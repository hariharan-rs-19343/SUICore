//
//  LetterAvatar.swift
//  SUICore
//
//  Created by Hariharan R S on 23/12/24.
//

import SwiftUI

/// A SwiftUI view that displays a letter avatar generated from a person's name.
///
/// Renders up to two initials on a deterministic background color derived from the name.
/// By default the background color is auto-computed; pass `autoColor: false` to supply
/// your own via `.background(...)`.
///
/// **Usage:**
/// ```swift
/// // Auto color, circle shape
/// LetterAvatarView("John Doe")
///     .frame(width: 36, height: 36)
///     .clipShape(Circle())
///
/// // Custom background
/// LetterAvatarView("John Doe", autoColor: false)
///     .frame(width: 36, height: 36)
///     .background(Circle().fill(.purple))
/// ```
public struct LetterAvatarView: View {

    private let name: String
    private let autoColor: Bool

    public init(_ name: String, autoColor: Bool = true) {
        self.name = name
        self.autoColor = autoColor
    }

    public var body: some View {
        ZStack {
            if autoColor {
                Rectangle().fill(Self.deterministicColor(for: name))
            }
            Text(Self.extractInitials(from: name))
                .font(.system(.body, weight: .bold))
                .foregroundStyle(.white)
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

    private static func deterministicColor(for string: String) -> Color {
        let minComponent: Int = 100
        let maxComponent: Int = 214
        let range = maxComponent - minComponent

        srand48(string.hashValue)
        let red   = CGFloat(minComponent + Int(drand48() * Double(range))) / 255.0
        let green = CGFloat(minComponent + Int(drand48() * Double(range))) / 255.0
        let blue  = CGFloat(minComponent + Int(drand48() * Double(range))) / 255.0

        return Color(.sRGB, red: red, green: green, blue: blue, opacity: 1)
    }
}

#if DEBUG
#Preview {
    HStack(spacing: 16) {
        LetterAvatarView("John Doe")
            .frame(width: 60, height: 60)
            .clipShape(Circle())

        LetterAvatarView("Alice Smith")
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 12))

        LetterAvatarView("Bob", autoColor: false)
            .frame(width: 60, height: 60)
            .background(Circle().fill(.purple))
    }
    .padding()
}
#endif
