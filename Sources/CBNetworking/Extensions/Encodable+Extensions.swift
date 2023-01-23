import Foundation

internal extension Encodable {
    var urlEncodedParameters: String? {
        guard
            let data = try? JSONEncoder().encode(self),
            let dictionary = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        else {
            return nil
        }
        
        return dictionary.reduce("") { "\($0!)\($1.0)=\($1.1)&" }
    }
}

