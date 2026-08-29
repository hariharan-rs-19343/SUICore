//
//  ZHDefaultLogger.swift
//  SUICore
//
//  Built-in, zero-configuration `ZHLoggerProtocol` implementation. Writes to
//  the unified system log via `os.Logger`, under a caller-supplied subsystem
//  (independent of the host app's own bundle identifier, and independent of
//  `ZOSLogs`), with one category per `ZHLogCategory`.
//
//  This only makes logs visible via Console.app / `log show` — it does NOT
//  surface anything inside the host app itself. Inject a custom
//  `ZHLoggerProtocol` implementation for that.
//

import Foundation
import OSLog

public struct ZHDefaultLogger: ZHLoggerProtocol {
    private let loggers: [ZHLogCategory: Logger]

    /// - Parameter subsystem: OSLog subsystem identifier grouping this
    ///   consumer's logs in Console.app, e.g. `"com.zharehub.sdk"`. Defaults
    ///   to a generic SUICore identifier; pass your own to distinguish your
    ///   package/app's logs from any other `ZHDefaultLogger` consumer's.
    public init(subsystem: String = "com.suicore") {
        loggers = [
            .androidParsing: Logger(subsystem: subsystem, category: ZHLogCategory.androidParsing.rawValue),
            .iosParsing: Logger(subsystem: subsystem, category: ZHLogCategory.iosParsing.rawValue),
            .networking: Logger(subsystem: subsystem, category: ZHLogCategory.networking.rawValue)
        ]
    }

    public func log(level: ZHLogLevel, category: ZHLogCategory, message: String, metadata: [String: String]?) {
        guard let logger = loggers[category] else { return }
        let suffix = metadata.map { pairs in
            " " + pairs.sorted(by: { $0.key < $1.key }).map { "\($0.key)=\($0.value)" }.joined(separator: " ")
        } ?? ""
        let fullMessage = "\(message)\(suffix)"

        switch level {
        case .debug: logger.debug("\(fullMessage, privacy: .public)")
        case .info: logger.info("\(fullMessage, privacy: .public)")
        case .warning: logger.warning("\(fullMessage, privacy: .public)")
        case .error: logger.error("\(fullMessage, privacy: .public)")
        }
    }
}
