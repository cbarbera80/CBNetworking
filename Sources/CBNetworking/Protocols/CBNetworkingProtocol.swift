import Foundation
import Combine

public protocol CBNetworkingProtocol {
    associatedtype Endpoint: EndpointType
    func send<T: Decodable, E: Error & Decodable>(endpoint: Endpoint, cachePolicy: URLRequest.CachePolicy?, type: T.Type, error: E.Type) async throws -> (model: T, response: HTTPURLResponse)
    func send<T: Decodable>(endpoint: Endpoint, cachePolicy: URLRequest.CachePolicy?, type: T.Type) async throws -> (model: T, response: HTTPURLResponse)
    func send<T: Decodable>(endpoint: Endpoint, cachePolicy: URLRequest.CachePolicy?) -> AnyPublisher<T, Error>
    func send<T: Decodable>(endpoint: Endpoint, cachePolicy: URLRequest.CachePolicy?) async throws -> T
}
