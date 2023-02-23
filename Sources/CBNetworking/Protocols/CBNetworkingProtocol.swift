import Foundation
import Combine

public protocol CBNetworkingProtocol {
    associatedtype Endpoint: EndpointType
    func send<T: Decodable>(endpoint: Endpoint) async throws -> (model: T, response: URLResponse)
    func send<T: Decodable>(endpoint: Endpoint) -> AnyPublisher<T, Error>
}
