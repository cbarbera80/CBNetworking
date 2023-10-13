import Foundation

/// The protocol used to define the specifications necessary for a `CBNetworking`.
public protocol EndpointType {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var httpBody: HTTPBodyType? { get }
    var queryItems: [URLQueryItem]? { get }
    var headers: [String: Any]? { get }
    var shouldRetryOnFailure: Bool { get }
}
