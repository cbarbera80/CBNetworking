import Foundation

public enum CBNetworkingError: Error {
    case invalidUrl
    case invalidHTTPResponse
    case transportError(Error)
    case invalidResponse
    case invalidHTTPStatusCode
    case unauthorized
}
