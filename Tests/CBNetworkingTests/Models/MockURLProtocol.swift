import Foundation
import CBNetworking

class MockURLProtocol: URLProtocol {
    static var data: Data!
    
    override class func canInit(with request: URLRequest) -> Bool {
       true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }
    
    override func startLoading() {
        client?.urlProtocol(self, didLoad: Self.data)
        client?.urlProtocol(self, didReceive: HTTPURLResponse(), cacheStoragePolicy: .allowed)
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() { }
}
