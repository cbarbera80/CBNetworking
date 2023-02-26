import Foundation
import Combine

public protocol CBNetworkingProtocol {
    associatedtype Endpoint: EndpointType
    func send<T: Decodable>(endpoint: Endpoint, type: T.Type) async throws -> (model: T, response: HTTPURLResponse)
    func send<T: Decodable>(endpoint: Endpoint) -> AnyPublisher<T, Error>
    func send<T: Decodable>(endpoint: Endpoint) async throws -> T
}
