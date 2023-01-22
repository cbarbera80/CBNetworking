import Foundation

public class CBNetworking<Endpoint: EndpointType>: CBNetworkingProtocol {
    private let decoder: JSONDecoder
    private let urlSession: URLSession
    private let adapters: [RequestAdapter]?
    private let logger: Loggable?
    
    public init(
        decoder: JSONDecoder = JSONDecoder(),
        urlSession: URLSession = .shared,
        adapters: [RequestAdapter]? = nil,
        logger: Loggable? = nil
    ) {
        self.decoder = decoder
        self.urlSession = urlSession
        self.adapters = adapters
        self.logger = logger
    }
    
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
    
    public func send<T: Decodable>(endpoint: Endpoint) async throws -> T {
        let request = try getRequest(from: endpoint)
        
        if let logger {
            let log = logger.log(request: request)
            print(log)
        }
        
        let (data, _) = try await urlSession.data(from: request)
        let response = try decoder.decode(T.self, from: data)
        return response
    }
}
