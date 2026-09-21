//
//  ToastDuration.swift
//  SUICore
//
//  Created by Hariharan R S on 02/05/26.
//


import Foundation

/// How long a toast stays on screen before being auto-dismissed.
public enum ToastDuration: Equatable, Sendable {

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

    /// Upper bound applied to `.seconds(_:)`.
    ///
    /// Anything longer is effectively `.persistent`, and clamping here keeps
    /// a stray value (or a non-finite one) from overflowing the sleep
    /// conversion in ``ToastManager``.
    public static let maximumInterval: TimeInterval = 600

    /// Resolved time interval, or `nil` when persistent.
    public var timeInterval: TimeInterval? {
        switch self {
        case .short:  return 1.5
        case .medium: return 3.0
        case .long:   return 5.0
        case .seconds(let seconds):
            guard seconds.isFinite else { return Self.maximumInterval }
            return min(max(0.1, seconds), Self.maximumInterval)
        case .persistent: return nil
        }
    }
}
