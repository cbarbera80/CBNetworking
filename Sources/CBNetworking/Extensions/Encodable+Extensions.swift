import Foundation

internal extension Encodable {
    var urlEncodedParameters: String? {
        guard
            let data = try? JSONEncoder().encode(self),
            let dictionary = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        else {
            return nil
        }
        
        let joined = dictionary.reduce("") { "\($0)\($1.0)=\($1.1)&" }
        let stripped = joined.dropLast()
        return String(stripped)
    }
}

