import Foundation

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
    
    public func send<T: Decodable>(endpoint: Endpoint) async throws -> T {
        let request = try getRequest(from: endpoint)
        
        print(logger?.log(request: request) ?? "")
        
        do {
            let (data, _) = try await urlSession.data(from: request)
            let response = try decoder.decode(T.self, from: data)
            return response
        } catch {
            print(logger?.log(error: error) ?? "")
            return try await shouldRetrySend(endpoint: endpoint, error: error)
        }
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
