import Foundation

public protocol CBNetworkingProtocol {
    associatedtype Endpoint: EndpointType
    func send<T: Decodable>(endpoint: Endpoint) async throws -> T
}
