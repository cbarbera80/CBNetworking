import Foundation

/// The protocol used to define HTTPBody type.
public enum HTTPBodyType {
    case raw(data: Data)
    case multipart(data: [MultipartData])
    case jsonEncodable(data: Encodable)
    case urlEncodable(data: Encodable)
    
    /// Whether or not the type is a multipart type.
    var isMultipart: Bool {
        switch self {
        case .raw, .jsonEncodable, .urlEncodable:
            return false
        case .multipart:
            return true
        }
    }
}
