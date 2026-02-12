//
//  ConnectionStatus.swift
//  SUICore
//
//  Created by Hariharan R S on 12/02/26.
//

import Foundation
import Network
import Combine

// MARK: - Observer Protocol
/// Conform to this protocol to receive network status change callbacks.
public protocol ConnectionStatusObserver: AnyObject {
    func connectionStatusDidChange(isAvailable: Bool)
}

// MARK: - ConnectionStatus
public final class ConnectionStatus: @unchecked Sendable {

    // MARK: - Singleton
    public static let shared = ConnectionStatus()

    // MARK: - Combine Publisher
    private let statusSubject = CurrentValueSubject<Bool, Never>(true)

    /// Publishes distinct network availability changes.
    public var isNetworkAvailablePublisher: AnyPublisher<Bool, Never> {
        statusSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    /// Current network availability (thread-safe via `CurrentValueSubject`).
    public var isNetworkAvailable: Bool {
        statusSubject.value
    }

    // MARK: - Private Properties
    private let monitor: NWPathMonitor
    private let monitorQueue = DispatchQueue(label: "com.connectionstatus.monitor", qos: .utility)
    private let lock = NSLock()
    private var observers = NSHashTable<AnyObject>.weakObjects()

    // MARK: - Initialization
    private init(monitor: NWPathMonitor = NWPathMonitor()) {
        self.monitor = monitor
        startMonitoring()
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - Observer Management
    /// Add a delegate-style observer. The observer is held weakly.
    public func addObserver(_ observer: ConnectionStatusObserver) {
        lock.withLock { observers.add(observer) }
    }

    /// Remove a previously added observer.
    public func removeObserver(_ observer: ConnectionStatusObserver) {
        lock.withLock { observers.remove(observer) }
    }

    // MARK: - Network Interface Info
    /// The `NWInterface.InterfaceType` of the primary interface, if any.
    public var currentInterfaceType: NWInterface.InterfaceType? {
        monitor.currentPath.availableInterfaces.first?.type
    }

    /// A human-readable description of the current network interface.
    public var currentInterfaceDescription: String {
        guard let type = currentInterfaceType else { return "Unknown" }
        switch type {
        case .wifi:            return "WiFi"
        case .cellular:        return "Cellular"
        case .loopback:        return "Loopback"
        case .wiredEthernet:   return "Wired Ethernet"
        case .other:           return "Other"
        @unknown default:      return "Unknown"
        }
    }

    // MARK: - Private
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let isAvailable = path.status == .satisfied
            self.statusSubject.send(isAvailable)
            self.notifyObservers(isAvailable: isAvailable)
        }
        monitor.start(queue: monitorQueue)
    }

    /// Snapshots the observer list outside the lock, then dispatches on main.
    private func notifyObservers(isAvailable: Bool) {
        let snapshot: [ConnectionStatusObserver] = lock.withLock {
            observers.allObjects.compactMap { $0 as? ConnectionStatusObserver }
        }

        DispatchQueue.main.async {
            snapshot.forEach { $0.connectionStatusDidChange(isAvailable: isAvailable) }
        }
    }
}

// MARK: - Combine / Closure Observation
public extension ConnectionStatus {
    /// Observe network changes via a closure. Retain the returned `AnyCancellable`.
    ///
    /// ```swift
    /// let token = ConnectionStatus.shared.observe { isAvailable in
    ///     print("Network:", isAvailable)
    /// }
    /// ```
    @discardableResult
    func observe(onChange callback: @escaping (Bool) -> Void) -> AnyCancellable {
        isNetworkAvailablePublisher
            .receive(on: DispatchQueue.main)
            .sink { callback($0) }
    }
}

// MARK: - Async/Await Support
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public extension ConnectionStatus {
    /// An `AsyncStream` that yields distinct network availability changes.
    ///
    /// ```swift
    /// for await isAvailable in ConnectionStatus.shared.networkStatusStream {
    ///     print("Network:", isAvailable)
    /// }
    /// ```
    var networkStatusStream: AsyncStream<Bool> {
        AsyncStream { continuation in
            let holder = SendableCancellableHolder()

            let cancellable = isNetworkAvailablePublisher
                .sink { continuation.yield($0) }

            holder.store(cancellable)

            continuation.onTermination = { _ in
                holder.cancel()
            }
        }
    }
}

/// Thread-safe, `Sendable` wrapper around `AnyCancellable`.
private final class SendableCancellableHolder: @unchecked Sendable {
    private let lock = NSLock()
    private var cancellable: AnyCancellable?

    func store(_ cancellable: AnyCancellable) {
        lock.withLock { self.cancellable = cancellable }
    }

    func cancel() {
        lock.withLock {
            cancellable?.cancel()
            cancellable = nil
        }
    }
}
