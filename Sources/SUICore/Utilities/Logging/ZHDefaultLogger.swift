//
//  ZHDefaultLogger.swift
//  SUICore
//
//  Built-in, zero-configuration `ZHLoggerProtocol` implementation. Writes to
//  the unified system log via `os.Logger`, under a caller-supplied subsystem,
//  with one category per `ZHLogCategory`.
//
//  This only makes logs visible via Console.app / `log show` — it does NOT
//  surface anything inside the host app itself. Inject a custom
//  `ZHLoggerProtocol` implementation for that.
//

import Foundation
import OSLog

public struct ZHDefaultLogger: ZHLoggerProtocol {
    private let subsystem: String

    /// - Parameter subsystem: OSLog subsystem identifier grouping this
    ///   consumer's logs in Console.app, e.g. `"com.zharehub.sdk"`. Defaults
    ///   to a generic SUICore identifier; pass your own to distinguish your
    ///   package/app's logs from any other `ZHDefaultLogger` consumer's.
    public init(subsystem: String = "com.suicore") {
        self.subsystem = subsystem
    }

    public func log(level: LogLevel, category: ZHLogCategory = .general, message: String, metadata: [String: String]?, file: String, function: String, line: Int) {
        let logger = Logger(subsystem: subsystem, category: category.description)
        let fileName = (file as NSString).lastPathComponent
        let suffix = metadata.map { pairs in
            " " + pairs.sorted(by: { $0.key < $1.key }).map { "\($0.key)=\($0.value)" }.joined(separator: " ")
        } ?? ""
        
        let logMessage = "[\(level.rawValue)] \(fileName):\(line) \(function) -> \(message)\(suffix)"

        switch level {
        case .debug: logger.debug("\(logMessage, privacy: .auto)")
        case .info: logger.info("\(logMessage, privacy: .auto)")
        case .notice: logger.notice("\(logMessage, privacy: .auto)")
        case .warning: logger.warning("\(logMessage, privacy: .auto)")
        case .error: logger.error("\(logMessage, privacy: .auto)")
        case .critical: logger.critical("\(logMessage, privacy: .auto)")
        }
    }
}
