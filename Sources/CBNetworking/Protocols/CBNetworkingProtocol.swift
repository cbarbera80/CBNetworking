import Foundation
import Combine

public protocol CBNetworkingProtocol {
    associatedtype Endpoint: EndpointType
    func send<T: Decodable>(endpoint: Endpoint) async throws -> T
    func send<T: Decodable>(endpoint: Endpoint) -> AnyPublisher<T, Error>
}
