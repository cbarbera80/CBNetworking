import Foundation

/// The Loggable protocol used to define the behaviour of the logger of the `CBNetworking`
public protocol Loggable {
    func log(request: URLRequest)
    func log(error: Error)
}

public extension Loggable {
    func log(request: URLRequest) {}
    func log(error: Error) {}
}
