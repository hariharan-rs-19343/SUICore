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
//  accepts one, or set `ZHLogging.current` once at launch.
//

import Foundation

/// Log level enumeration to define the type of log messages.
public enum LogLevel: String {
    case debug = "🔍 DEBUG"
    case info = "ℹ️ INFO"
    case notice = "📢 NOTICE"
    case warning = "⚠️ WARNING"
    case error = "❌ ERROR"
    case critical = "🚨 CRITICAL"
}

/// Subsystem area a log event originates from, so a `ZHLoggerProtocol`
/// implementation can route or filter by domain.
///
/// A small set of cases covers SUICore's own subsystems; `.custom` lets any
/// other subsystem or a client app log under an arbitrary category without
/// needing to modify this enum.
public enum ZHLogCategory: Sendable, Hashable {
    case general
    case ui
    case networking
    case persistence
    case security
    case custom(String)
}

extension ZHLogCategory: CustomStringConvertible {
    /// The category name a logging backend (e.g. OSLog) should use.
    public var description: String {
        switch self {
        case .general: return "General"
        case .ui: return "UI"
        case .networking: return "Networking"
        case .persistence: return "Persistence"
        case .security: return "Security"
        case .custom(let name): return name
        }
    }
}

public protocol ZHLoggerProtocol: Sendable {
    /// - Parameters:
    ///   - category: Which subsystem the event originated from.
    ///   - message: Human-readable description of the event.
    ///   - metadata: Structured key/value details. Should never contain raw
    ///     header values, query parameter values, or body content — only
    ///     sizes, names, and other non-sensitive metadata.
    ///   - file: Source file the event was logged from.
    ///   - function: Function the event was logged from.
    ///   - line: Line the event was logged from.
    func info(category: ZHLogCategory, message: String, metadata: [String: String]?, file: String, function: String, line: Int)
    
    func debug(category: ZHLogCategory, message: String, metadata: [String: String]?, file: String, function: String, line: Int)
    
    func warning(category: ZHLogCategory, message: String, metadata: [String: String]?, file: String, function: String, line: Int)
    
    func error(category: ZHLogCategory, message: String, metadata: [String: String]?, file: String, function: String, line: Int)
    
    func critical(category: ZHLogCategory, message: String, metadata: [String: String]?, file: String, function: String, line: Int)
    
    func notice(category: ZHLogCategory, message: String, metadata: [String: String]?, file: String, function: String, line: Int)
}

public extension ZHLoggerProtocol {
    /// Convenience overload — captures the call site automatically and
    /// defaults `metadata` to `nil`.
    func info(category: ZHLogCategory, message: String, metadata: [String: String]? = nil, file: String = #fileID, function: String = #function, line: Int = #line) {
        info(category: category, message: message, metadata: metadata, file: file, function: function, line: line)
    }
    
    func debug(category: ZHLogCategory, message: String, metadata: [String: String]? = nil, file: String = #fileID, function: String = #function, line: Int = #line) {
        debug(category: category, message: message, metadata: metadata, file: file, function: function, line: line)
    }
    
    func warning(category: ZHLogCategory, message: String, metadata: [String: String]? = nil, file: String = #fileID, function: String = #function, line: Int = #line) {
        warning(category: category, message: message, metadata: metadata, file: file, function: function, line: line)
    }
    
    func error(category: ZHLogCategory, message: String, metadata: [String: String]? = nil, file: String = #fileID, function: String = #function, line: Int = #line) {
        error(category: category, message: message, metadata: metadata, file: file, function: function, line: line)
    }
    
    func critical(category: ZHLogCategory, message: String, metadata: [String: String]? = nil, file: String = #fileID, function: String = #function, line: Int = #line) {
        critical(category: category, message: message, metadata: metadata, file: file, function: function, line: line)
    }
    
    func notice(category: ZHLogCategory, message: String, metadata: [String: String]? = nil, file: String = #fileID, function: String = #function, line: Int = #line) {
        notice(category: category, message: message, metadata: metadata, file: file, function: function, line: line)
    }
}

