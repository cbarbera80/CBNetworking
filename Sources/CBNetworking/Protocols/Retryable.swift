import Foundation

public protocol Retryable {
    func retry(_ endpoint: EndpointType, forError error: Error) async throws -> RetryType
}
