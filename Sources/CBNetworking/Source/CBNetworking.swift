import Foundation
import Combine

public class CBNetworking<Endpoint: EndpointType>: CBNetworkingProtocol {
    private let decoder: JSONDecoder
    private let urlSession: URLSession
    private let adapters: [RequestAdapter]?
    private let logger: Loggable?
    private let retryable: Retryable?
    
    // MARK: - Public
    
    public init(
        decoder: JSONDecoder = JSONDecoder(),
        urlSession: URLSession = .shared,
        adapters: [RequestAdapter]? = nil,
        logger: Loggable? = nil,
        retryable: Retryable? = nil
    ) {
        self.decoder = decoder
        self.urlSession = urlSession
        self.adapters = adapters
        self.logger = logger
        self.retryable = retryable
    }
    
    public func send<T: Decodable>(endpoint: Endpoint, type: T.Type) async throws -> (model: T, response: HTTPURLResponse)  {
        let request = try getRequest(from: endpoint)
        
        logger?.log(request: request)
        
        do {
            let (data, urlResponse) = try await urlSession.data(from: request)
            let model = try decoder.decode(T.self, from: data)
            return (model: model, response: urlResponse as! HTTPURLResponse)
        } catch {
            logger?.log(error: error)
            return try await shouldRetrySend(endpoint: endpoint, error: error, type: type)
        }
    }
    
    public func send<T: Decodable>(endpoint: Endpoint) async throws -> T {
        let request = try getRequest(from: endpoint)
        
        logger?.log(request: request)
        
        do {
            let (data, _) = try await urlSession.data(from: request)
            let model = try decoder.decode(T.self, from: data)
            return model
        } catch {
            logger?.log(error: error)
            return try await shouldRetrySend(endpoint: endpoint, error: error)
        }
    }
    
    public func send<T: Decodable>(endpoint: Endpoint) -> AnyPublisher<T, Error> {
        guard
            let request = try? getRequest(from: endpoint)
        else {
            return Fail(error: CBNetworkingError.invalidUrl)
                .eraseToAnyPublisher()
        }
        
        logger?.log(request: request)
        
        return urlSession.dataTaskPublisher(for: request)
            .mapError { CBNetworkingError.transportError($0) }
            .tryMap { (data, response) -> (data: Data, response: URLResponse) in
                guard let urlResponse = response as? HTTPURLResponse else {
                    throw CBNetworkingError.invalidResponse
                }
                
                if (200...299) ~=  urlResponse.statusCode {
                    return (data, response)
                } else {
                    throw CBNetworkingError.invalidHTTPStatusCode
                }
            }
            .map(\.data)
            .decode(type: T.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    // MARK: - Internal
    
    func getRequest(from endpoint: Endpoint) throws -> URLRequest {
        try buildURLRequest(for: endpoint)
    }
    
    func buildURLRequest(for request: Endpoint) throws -> URLRequest {
        try URLRequestBuilder(with: request.baseURL)
            .set(path: request.path)
            .set(method: request.method)
            .set(headers: request.headers)
            .set(httpBody: request.httpBody)
            .set(queryItems: request.queryItems)
            .add(adapters: adapters)
            .build()
    }

    func shouldRetrySend<T: Decodable>(endpoint: Endpoint, error: Error, type: T.Type) async throws -> (model: T, response: HTTPURLResponse) {
        guard let retryable = retryable else { throw error }
        
        switch try await retryable.retry(endpoint, forError: error) {
        case .shouldRetry:
            return try await send(endpoint: endpoint, type: type)
        case .doNotRetry:
            throw error
        }
    }
    
    func shouldRetrySend<T: Decodable>(endpoint: Endpoint, error: Error) async throws -> T {
        guard let retryable = retryable else { throw error }
        
        switch try await retryable.retry(endpoint, forError: error) {
        case .shouldRetry:
            return try await send(endpoint: endpoint)
        case .doNotRetry:
            throw error
        }
    }
}
