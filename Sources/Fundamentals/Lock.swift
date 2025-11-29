//
//  Created by Anton Spivak
//

// MARK: - Lock

/// A simple thread-safe lock that wraps a generic value, providing synchronized
/// access via `withLockedValue(_:)`.
///
/// **Example**:
/// ```swift
/// let counterLock = Lock(0)
///
/// Task.detached {
///   try await Task.sleep(nanoseconds: 1_000_000)
///   counterLock.withLockedValue { $0 += 1 }
/// }
///
/// let finalCount = counterLock.withLockedValue { $0 }
/// print(finalCount)
/// ```
public struct Lock<Value>: @unchecked Sendable {
    // MARK: Lifecycle

    /// Creates a lock protecting the given `value`.
    /// - Parameter value: The initial value to store.
    public init(_ value: Value) {
        self.lock = .init(value)
    }

    // MARK: Public

    /// Executes a closure synchronously with exclusive access to the
    /// wrapped `Value`. The closure can read and modify `Value` safely
    /// across concurrent tasks/threads.
    ///
    /// - Parameter body: A closure that receives `inout Value`.
    /// - Returns: Whatever the closure returns.
    /// - Throws: Rethrows any error from the closure.
    @inlinable
    public func withLockedValue<R>(
        _ body: @Sendable (inout Value) throws -> R
    ) rethrows -> R where R: Sendable {
        lock._lock()
        defer { lock._unlock() }
        return try body(&lock.value)
    }

    // MARK: Internal

    @usableFromInline
    let lock: Implementation
}

#if canImport(Darwin)
import os
#elseif canImport(Musl)
import Musl
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Bionic)
import Bionic
#else
#error("Unsupported platform")
#endif

// MARK: Lock.Implementation

extension Lock {
    /// The internal class that wraps a `pthread_mutex_t` and the stored value.
    @usableFromInline
    final class Implementation {
        // MARK: Lifecycle

        init(_ value: Value) {
            var attributes = pthread_mutexattr_t()
            pthread_mutexattr_init(&attributes)

            let lock = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
            let status = pthread_mutex_init(lock, &attributes)
            precondition(status == 0, "pthread_mutex_init: \(status)")

            self.value = value
            self.lock = lock
        }

        deinit {
            let status = pthread_mutex_destroy(lock)
            precondition(status == 0, "pthread_mutex_destroy: \(status)")
            self.lock.deallocate()
        }

        // MARK: Internal

        @usableFromInline
        var value: Value

        @usableFromInline @inline(__always)
        func _lock() {
            let status = pthread_mutex_lock(lock)
            precondition(status == 0, "pthread_mutex_lock: \(status)")
        }

        @usableFromInline @inline(__always)
        func _unlock() {
            let status = pthread_mutex_unlock(lock)
            precondition(status == 0, "pthread_mutex_unlock: \(status)")
        }

        @usableFromInline @inline(__always)
        func _trylock() -> Bool {
            pthread_mutex_trylock(lock) == 0
        }

        // MARK: Private

        private let lock: UnsafeMutablePointer<pthread_mutex_t>
    }
}
