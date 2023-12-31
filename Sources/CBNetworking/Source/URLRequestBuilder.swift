import Foundation

class URLRequestBuilder {
    var adapters: [RequestAdapter] = []
    var baseURL: URL
    var path: String?
    var method: HTTPMethod = .get
    var headers: [String: Any]?
    var queryItems: [URLQueryItem]?
    var httpBody: HTTPBodyType?
    var timeInterval: TimeInterval = 100
    
    private let encoder: JSONEncoder
    
    init(with baseURL: URL, encoder: JSONEncoder = JSONEncoder()) {
        self.baseURL = baseURL
        self.encoder = encoder
    }
    
    @discardableResult
     func add(adapters: [RequestAdapter]?) -> URLRequestBuilder {
         guard let adapters = adapters else { return self }
         self.adapters.append(contentsOf: adapters)
         return self
     }
    
    @discardableResult
    func set(method: HTTPMethod) -> Self {
        self.method = method
        return self
    }
    
    @discardableResult
    func set(path: String) -> Self {
        self.path = path
        return self
    }

    @discardableResult
    func set(headers: [String: Any]?) -> Self {
        self.headers = headers
        return self
    }
    
    @discardableResult
    func set(timeoutInterval: TimeInterval) -> Self {
        self.timeInterval = timeoutInterval
        return self
    }
    
    @discardableResult
    func set(queryItems: [URLQueryItem]?) -> Self {
        self.queryItems = queryItems
        return self
    }
    
    @discardableResult
    func set(httpBody: HTTPBodyType?) -> Self {
        self.httpBody = httpBody
        return self
    }
    
    func buildURL() -> URL? {
        guard let path else { return nil }
        return baseURL.appendingPathComponent(path)
    }
    
    func build() throws -> URLRequest {
        guard let url = buildURL() else {
            throw CBNetworkingError.invalidUrl
        }
        
        // Build parameters
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            throw CBNetworkingError.invalidUrl
        }
        
        if let queryItems = queryItems {
            urlComponents.queryItems = queryItems
        }
        
        
        guard let finalUrl = urlComponents.url else {
            throw CBNetworkingError.invalidUrl
        }
        
        var urlRequest = URLRequest(url: finalUrl,
                                    cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                    timeoutInterval: timeInterval)
        
        try adapters.forEach {
            urlRequest = try $0.adapt(urlRequest)
        }
        
        urlRequest.httpMethod = method.rawValue
        
        headers?.forEach {
            urlRequest.addValue($0.value as! String, forHTTPHeaderField: $0.key)
        }
      
        let body = buildBody()
        
        if let httpBody, let boundary = body?.boundary, httpBody.isMultipart {
            urlRequest.addValue(boundary, forHTTPHeaderField: "Content-Type")
        }
        
        urlRequest.httpBody = body?.data
        
        return urlRequest
    }
    
    private func buildBody() -> (data: Data?, boundary: String?)? {
        
        guard let httpBody else { return nil }
        
        switch httpBody {
        case .raw(let data):
            return (data: data, boundary: nil)
       
        case .multipart(let request):
            return (data: request.httpBody, boundary: request.httpContentTypeHeadeValue)
            
        case .jsonEncodable(let data):
            return (data: try? encoder.encode(data), boundary: nil)
            
        case .urlEncodable(let data):
            let d = data.urlEncodedParameters?.data(using: .utf8)
            return (data: d, boundary: nil)
        }
    }
}
