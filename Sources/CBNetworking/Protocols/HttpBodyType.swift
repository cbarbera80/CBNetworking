import Foundation

/// The protocol used to define HTTPBody type.
public enum HTTPBodyType {
    case raw(data: Data)
    case multipart(data: [MultipartData])
    case encodable(data: Encodable)
    
    /// Whether or not the type is a multipart type.
    var isMultipart: Bool {
        switch self {
        case .raw:
            return false
        case .multipart:
            return true
        case .encodable:
            return false
        }
    }
}
