//
//  ZOSLogs.swift
//  MEAdmin
//
//  Created by Hariharan R S on 20/02/25.
//

import Foundation
import OSLog

/// Log level enumeration to define the type of log messages
public enum LogLevel: String {
    case debug = "🔍 DEBUG"
    case info = "ℹ️ INFO"
    case notice = "📢 NOTICE"
    case warning = "⚠️ WARNING"
    case error = "❌ ERROR"
    case critical = "🚨 CRITICAL"
}

/// ZOSLogs class using Swift's native OSLog framework
public final class ZOSLogs: Sendable {
    
    /// Shared instance for global access
    public static let shared = ZOSLogs()
    
    // Create logger instance with subsystem and category
    private let logger: Logger
    
    // Initialize logger with proper subsystem and category
    private init(subsystem: String? = Bundle.main.bundleIdentifier, category: String = "AppLogs") {
        guard let bundleIdentifier = subsystem else {
            fatalError("Could not retrieve bundle identifier")
        }
        
        self.logger = Logger(subsystem: bundleIdentifier, category: category)
    }
    
    /// Log a message with a specific log level
    private func log(_ level: LogLevel,
                    message: String,
                    file: String = #file,
                    function: String = #function,
                    line: Int = #line) {
        
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(level.rawValue)] \(fileName):\(line) \(function) -> \(message)"
        
        // Log to system using modern Logger API
        switch level {
        case .debug:
            logger.debug("\(logMessage, privacy: .auto)")
        case .info:
            logger.info("\(logMessage, privacy: .auto)")
        case .notice:
            logger.notice("\(logMessage, privacy: .auto)")
        case .warning:
            logger.warning("\(logMessage, privacy: .auto)")
        case .error:
            logger.error("\(logMessage, privacy: .auto)")
        case .critical:
            logger.critical("\(logMessage, privacy: .auto)")
        }
    }
    
    // Public logging methods with privacy control
    public func debug(_ message: String,
               file: String = #file,
               function: String = #function,
               line: Int = #line) {
        log(.debug, message: message, file: file, function: function, line: line)
    }
    
    public func info(_ message: String,
              file: String = #file,
              function: String = #function,
              line: Int = #line) {
        log(.info, message: message, file: file, function: function, line: line)
    }
    
    public func notice(_ message: String,
                file: String = #file,
                function: String = #function,
                line: Int = #line) {
        log(.notice, message: message, file: file, function: function, line: line)
    }
    
    public func warning(_ message: String,
                 file: String = #file,
                 function: String = #function,
                 line: Int = #line) {
        log(.warning, message: message, file: file, function: function, line: line)
    }
    
    public func error(_ message: String,
               file: String = #file,
               function: String = #function,
               line: Int = #line) {
        log(.error, message: message, file: file, function: function, line: line)
    }
    
    public func critical(_ message: String,
                  file: String = #file,
                  function: String = #function,
                  line: Int = #line) {
        log(.critical, message: message, file: file, function: function, line: line)
    }
}
