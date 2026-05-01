//
//  ToastDuration.swift
//  SUICore
//
//  Created by Hariharan R S on 02/05/26.
//


import Foundation

/// How long a toast stays on screen before being auto-dismissed.
public enum ToastDuration: Equatable {

    /// 1.5 seconds.
    case short

    /// 3 seconds.
    case medium

    /// 5 seconds.
    case long

    /// Custom duration in seconds.
    case seconds(TimeInterval)

    /// Toast must be dismissed manually (tap, swipe, programmatic).
    case persistent

    /// Resolved time interval, or `nil` when persistent.
    public var timeInterval: TimeInterval? {
        switch self {
        case .short:           return 1.5
        case .medium:          return 3.0
        case .long:            return 5.0
        case .seconds(let s):  return max(0.1, s)
        case .persistent:      return nil
        }
    }
}
