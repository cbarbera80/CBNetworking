import Foundation
import CBNetworking

class OAuth2Adapter: RequestAdapter {
    
    private let bearer: String

    init(bearer: String) {
        self.bearer = bearer
    }
    
    func adapt(_ request: URLRequest) -> URLRequest {
        var request = request
        request.addValue("Authorization", forHTTPHeaderField: "Bearer \(bearer)")
        return request
    }
}
