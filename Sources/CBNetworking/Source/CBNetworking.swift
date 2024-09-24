import Foundation
import Combine

public class CBNetworking<Endpoint: EndpointType>: CBNetworkingProtocol {
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let urlSession: URLSession
    private let adapters: [RequestAdapter]?
    private let logger: Loggable?
    public var retryable: Retryable?
    let baseURL: URL?
    
    // MARK: - Public
    
    public init(
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder(),
        urlSession: URLSession = .shared,
        adapters: [RequestAdapter]? = nil,
        logger: Loggable? = nil,
        retryable: Retryable? = nil,
        baseURL: URL? = nil
    ) {
        self.decoder = decoder
        self.encoder = encoder
        self.urlSession = urlSession
        self.adapters = adapters
        self.logger = logger
        self.retryable = retryable
        self.baseURL = baseURL
    }
    
    public func send<T: Decodable>(endpoint: Endpoint, cachePolicy: URLRequest.CachePolicy? = nil, type: T.Type) async throws -> (model: T, response: HTTPURLResponse)  {
        let request = try getRequest(from: endpoint, cachePolicy: cachePolicy)
        
        logger?.log(request: request)
        
        do {
            let (data, urlResponse) = try await urlSession.data(from: request)
            let model = try decoder.decode(T.self, from: data)
            return (model: model, response: urlResponse as! HTTPURLResponse)
        } catch {
            logger?.log(request: request, error: error)
            return try await shouldRetrySend(endpoint: endpoint, error: error, type: type)
        }
    }
    
    public func send<T: Decodable, E: Error & Decodable>(endpoint: Endpoint, cachePolicy: URLRequest.CachePolicy? = nil, type: T.Type, error: E.Type) async throws -> (model: T, response: HTTPURLResponse)  {
        let request = try getRequest(from: endpoint, cachePolicy: cachePolicy)
        
        logger?.log(request: request)
        
        do {
            let (data, urlResponse) = try await urlSession.data(from: request)
            let model = try decoder.decode(T.self, from: data)
            return (model: model, response: urlResponse as! HTTPURLResponse)
        } catch let NetworkError.error(associatedError, statusCode) {
            let networkingError = associatedError as! CBNetworkingError
            
            logger?.log(request: request, error: networkingError, statusCode: statusCode)
            
            switch networkingError {
            case .invalidHTTPStatusCode(let data):
                let e = try decoder.decode(E.self, from: data)
                throw e
                
            default:
                throw networkingError
            }
        } catch {
            logger?.log(request: request, error: error)
            return try await shouldRetrySend(endpoint: endpoint, error: error, type: type)
        }
    }
    
    public func send<T: Decodable, E: Error & Decodable>(endpoint: Endpoint, cachePolicy: URLRequest.CachePolicy? = nil, error: E.Type) async throws -> T {
        let request = try getRequest(from: endpoint, cachePolicy: cachePolicy)
        
        logger?.log(request: request)
        
        do {
            let (data, _) = try await urlSession.data(from: request)
            let model = try decoder.decode(T.self, from: data)
            return model
        } catch let NetworkError.error(associatedError, statusCode) {
            let networkingError = associatedError as! CBNetworkingError
            
            logger?.log(request: request, error: networkingError, statusCode: statusCode)
            
            switch networkingError {
            case .invalidHTTPStatusCode(let data):
                let e = try decoder.decode(E.self, from: data)
                throw e
                
            default:
                throw networkingError
            }
        } catch {
            logger?.log(request: request, error: error)
            return try await shouldRetrySend(endpoint: endpoint, error: error)
        }
    }
    
    public func send<T: Decodable>(endpoint: Endpoint, cachePolicy: URLRequest.CachePolicy? = nil) async throws -> T {
        let request = try getRequest(from: endpoint, cachePolicy: cachePolicy)
        
        logger?.log(request: request)
        
        do {
            let (data, _) = try await urlSession.data(from: request)
            let model = try decoder.decode(T.self, from: data)
            return model
        } catch {
            logger?.log(request: request, error: error)
            return try await shouldRetrySend(endpoint: endpoint, error: error)
        }
    }
    
    public func send(endpoint: Endpoint, cachePolicy: URLRequest.CachePolicy? = nil) async throws -> Data {
        let request = try getRequest(from: endpoint, cachePolicy: cachePolicy)
        
        logger?.log(request: request)
        
        do {
            let (data, _) = try await urlSession.data(from: request)
            return data
        } catch {
            logger?.log(request: request, error: error)
            return try await shouldRetrySend(endpoint: endpoint, error: error)
        }
    }
    
    public func send(endpoint: Endpoint, cachePolicy: URLRequest.CachePolicy? = nil) async throws {
        let request = try getRequest(from: endpoint, cachePolicy: cachePolicy)
        
        logger?.log(request: request)
        
        do {
            _ = try await urlSession.data(from: request)
        } catch {
            logger?.log(request: request, error: error)
            return try await shouldRetrySend(endpoint: endpoint, error: error)
        }
    }
    
    public func send<E: Error & Decodable>(endpoint: Endpoint, cachePolicy: URLRequest.CachePolicy? = nil, error: E.Type) async throws {
        let request = try getRequest(from: endpoint, cachePolicy: cachePolicy)
        
        logger?.log(request: request)
        
        do {
            _ = try await urlSession.data(from: request)
        } catch let NetworkError.error(associatedError, statusCode) {
            let networkingError = associatedError as! CBNetworkingError
            
            logger?.log(request: request, error: networkingError, statusCode: statusCode)
            
            switch networkingError {
            case .invalidHTTPStatusCode(let data):
                let e = try decoder.decode(E.self, from: data)
                throw e
                
            default:
                throw networkingError
            }
        } catch {
            logger?.log(request: request, error: error)
            return try await shouldRetrySend(endpoint: endpoint, error: error)
        }
    }
    
    public func send<T: Decodable>(endpoint: Endpoint, cachePolicy: URLRequest.CachePolicy? = nil) -> AnyPublisher<T, Error> {
        guard
            let request = try? getRequest(from: endpoint, cachePolicy: cachePolicy)
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
                } else if urlResponse.statusCode == 401 || urlResponse.statusCode == 403 {
                    throw CBNetworkingError.unauthorized
                } else {
                    throw CBNetworkingError.invalidHTTPStatusCode(data: data)
                }
            }
            .map(\.data)
            .decode(type: T.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    // MARK: - Internal
    
    func getRequest(from endpoint: Endpoint, cachePolicy: URLRequest.CachePolicy?) throws -> URLRequest {
        try buildURLRequest(for: endpoint, cachePolicy: cachePolicy)
    }
    
    func buildURLRequest(for request: Endpoint, cachePolicy: URLRequest.CachePolicy?) throws -> URLRequest {
        var request = try URLRequestBuilder(with: baseURL ?? request.baseURL, encoder: encoder)
            .set(path: request.path)
            .set(method: request.method)
            .set(headers: request.headers)
            .set(httpBody: request.httpBody)
            .set(queryItems: request.queryItems)
            .add(adapters: adapters)
            .build()
        
        if let cachePolicy = cachePolicy {
            request.cachePolicy = cachePolicy
        }
        
        return request
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
    
    func shouldRetrySend(endpoint: Endpoint, error: Error) async throws {
        guard let retryable = retryable else { throw error }
        
        switch try await retryable.retry(endpoint, forError: error) {
        case .shouldRetry:
            return try await send(endpoint: endpoint)
        case .doNotRetry:
            throw error
        }
    }
}
