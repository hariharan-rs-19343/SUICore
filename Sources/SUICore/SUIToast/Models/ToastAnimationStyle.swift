//
//  ToastAnimationStyle.swift
//  SUICore
//
//  Created by Hariharan R S on 02/05/26.
//


import SwiftUI

/// Transition families supported by the framework. Each case is mapped to
/// a concrete `AnyTransition` by the container view, so a single switch is
/// the only place we need to describe motion.
public enum ToastAnimationStyle: Equatable, Sendable {
    case fade
    case slide
    case spring
    case scale

    /// Resolve to a SwiftUI transition for the given position.
    ///
    /// - Parameter reduceMotion: When `true` every style collapses to a plain
    ///   cross-fade, honouring the system Reduce Motion setting.
    func transition(for position: ToastPosition, reduceMotion: Bool = false) -> AnyTransition {
        guard !reduceMotion else { return .opacity }

        switch self {
        case .fade:
            return .opacity

        case .slide:
            let edge: Edge = position == .top ? .top : .bottom
            return .move(edge: edge).combined(with: .opacity)

        case .spring:
            let edge: Edge = position == .top ? .top : .bottom
            return .move(edge: edge)
                .combined(with: .opacity)
                .combined(with: .scale(scale: 0.92, anchor: position == .top ? .top : .bottom))

        case .scale:
            return .scale(scale: 0.85)
                .combined(with: .opacity)
        }
    }

    /// Resolved animation curve.
    ///
    /// - Parameter reduceMotion: When `true` the springs are replaced by a
    ///   short ease so nothing overshoots.
    func animation(reduceMotion: Bool = false) -> Animation {
        guard !reduceMotion else { return .easeInOut(duration: 0.2) }

        switch self {
        case .fade:   return .easeInOut(duration: 0.25)
        case .slide:  return .easeOut(duration: 0.30)
        case .spring: return .spring(response: 0.45, dampingFraction: 0.78, blendDuration: 0)
        case .scale:  return .spring(response: 0.35, dampingFraction: 0.82, blendDuration: 0)
        }
    }
}
