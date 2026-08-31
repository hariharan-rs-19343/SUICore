//
//  ZHLogging.swift
//  SUICore
//
//  Namespace holding the SDK-wide default logger. SUICore's own internal call
//  sites log through `ZHLogging.current` instead of instantiating a logger at
//  every call site. A host app can override `current` once — typically at
//  app or SDK bootstrap, before concurrent logging begins — to redirect all
//  of SUICore's internal logs (and, if desired, its own logs through the
//  same conformance) to a custom `ZHLoggerProtocol` implementation.
//

import Foundation

public enum ZHLogging {
    private static let lock = NSLock()
    private nonisolated(unsafe) static var _current: any ZHLoggerProtocol = ZHDefaultLogger()

    /// The logger SUICore (and, optionally, the host app) currently logs
    /// through. Intended to be set once, early (e.g. app launch or an SDK
    /// `configure(...)` entry point) before concurrent logging traffic
    /// begins; reads and writes are lock-protected regardless.
    public static var current: any ZHLoggerProtocol {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _current
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _current = newValue
        }
    }
}
