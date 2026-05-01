//
//  ToastStyle.swift
//  SUICore
//
//  Created by Hariharan R S on 02/05/26.
//


import SwiftUI

/// Ready-made toast appearances covering the most common semantic
/// categories. Use `.custom(_:)` to supply your own conformer.
public enum ToastStyle: ToastStyleProviding {
    case success
    case error
    case warning
    case info
    case neutral

    /// Inject a fully custom style without subclassing or modifying the
    /// framework. Anything that conforms to ``ToastStyleProviding`` works.
    case custom(any ToastStyleProviding)

    public var iconSystemName: String? {
        switch self {
        case .success:        return "checkmark.circle.fill"
        case .error:          return "xmark.octagon.fill"
        case .warning:        return "exclamationmark.triangle.fill"
        case .info:           return "info.circle.fill"
        case .neutral:        return nil
        case .custom(let s):  return s.iconSystemName
        }
    }

    public var iconColor: Color {
        switch self {
        case .success:        return .green
        case .error:          return .red
        case .warning:        return .orange
        case .info:           return .blue
        case .neutral:        return .secondary
        case .custom(let s):  return s.iconColor
        }
    }

    public var textColor: Color {
        if case let .custom(style) = self { return style.textColor }
        return .primary
    }

    public var accentColor: Color {
        switch self {
        case .success:        return .green
        case .error:          return .red
        case .warning:        return .orange
        case .info:           return .blue
        case .neutral:        return .accentColor
        case .custom(let s):  return s.accentColor
        }
    }

    public var borderColor: Color {
        if case let .custom(style) = self { return style.borderColor }
        return accentColor.opacity(0.18)
    }
}
