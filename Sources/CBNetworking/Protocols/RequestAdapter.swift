import Foundation

public protocol RequestAdapter {
    func adapt(_ request: URLRequest) throws -> URLRequest
}

public protocol ResponseAdapter {
    func adapt(_ response: URLResponse)
}
