import Foundation

enum RetryManager {
    static func retry<T>(_ operation: () async throws -> T) async throws -> T {
        try await operation()
    }
}
