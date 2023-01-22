import Foundation

public protocol RequestAdapter {
    func adapt(_ request: URLRequest) throws -> URLRequest
}
