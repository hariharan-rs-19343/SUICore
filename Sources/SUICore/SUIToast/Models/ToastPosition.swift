//
//  ToastPosition.swift
//  SUICore
//
//  Created by Hariharan R S on 02/05/26.
//

import Foundation
import SwiftUI

/// Where a toast should appear within the safe area of its host view.
public enum ToastPosition: Equatable {
    case top
    case bottom

    /// SwiftUI alignment used by the container to anchor the toast.
    var alignment: Alignment {
        switch self {
        case .top:    return .top
        case .bottom: return .bottom
        }
    }

    /// Sign multiplier for slide animations (positive = downward).
    var slideSign: CGFloat {
        switch self {
        case .top:    return -1
        case .bottom: return  1
        }
    }
}
