//
//  ZHLoggerProtocol.swift
//  SUICore
//
//  Consumer-injected logging abstraction, mirroring the "host app supplies an
//  implementation" shape used elsewhere in this ecosystem (e.g. ZhareHubSDK's
//  `ShellExecutorProtocol`).
//
//  A consuming package/app calls this for every significant event it wants
//  observable. By default (no logger injected) `ZHDefaultLogger` is used,
//  which only writes to the unified system log (visible via Console.app /
//  `log show`) — it does NOT surface anything inside the host app's own UI.
//  To capture, display, or forward events from within the host app, implement
//  `ZHLoggerProtocol` and inject an instance wherever the consuming package
//  accepts one.
//
//  Supersedes `ZOSLogs`, which is a fixed singleton with no way for a
//  consumer to intercept, redirect, or test its output.
//

import Foundation

/// Log severity used by `ZHLoggerProtocol`.
public enum ZHLogLevel: String, Sendable {
    case debug
    case info
    case warning
    case error
}

/// Subsystem area a log event originates from, so a `ZHLoggerProtocol`
/// implementation can route or filter by domain.
public enum ZHLogCategory: String, Sendable {
    case androidParsing
    case iosParsing
    case networking
}

public protocol ZHLoggerProtocol: Sendable {
    /// - Parameters:
    ///   - level: Severity of the event.
    ///   - category: Which subsystem the event originated from.
    ///   - message: Human-readable description of the event.
    ///   - metadata: Structured key/value details. Should never contain raw
    ///     header values, query parameter values, or body content — only
    ///     sizes, names, and other non-sensitive metadata.
    func log(level: ZHLogLevel, category: ZHLogCategory, message: String, metadata: [String: String]?)
}

public extension ZHLoggerProtocol {
    func log(level: ZHLogLevel, category: ZHLogCategory, message: String) {
        log(level: level, category: category, message: message, metadata: nil)
    }
}
