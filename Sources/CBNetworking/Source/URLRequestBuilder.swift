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
    
    init(with baseURL: URL) {
        self.baseURL = baseURL
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
        let boundary: String = UUID().uuidString
        
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
        
        if let httpBody, httpBody.isMultipart {
            urlRequest.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        }
        
        urlRequest.httpBody = buildBody(boundary: boundary)
        
        return urlRequest
    }
    
    private func buildBody(boundary: String) -> Data? {
        
        guard let httpBody else { return nil }
        
        switch httpBody {
        case .raw(let data):
            return data
        case .multipart(let multipartData):
            let httpMultipartData = NSMutableData()
            
            httpMultipartData.append("--\(boundary)\r\n")
            
            multipartData.forEach { data in
                httpMultipartData.append(data.dataFormField(from: data))
            }
            
            httpMultipartData.append("--\(boundary)--")
            
            return httpMultipartData as Data
            
        case .encodable(let data):
            return try? JSONEncoder().encode(data)
        }
    }
}
