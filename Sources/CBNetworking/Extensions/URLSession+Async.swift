import Foundation

public enum NetworkError: Error {
    case error(parent: Error, httpStatusCode: Int)
}

extension URLSession {
    func data(from request: URLRequest) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
           
            let task = self.dataTask(with: request) { data, response, error in
                guard let data = data, let response = response, let urlResponse = response as? HTTPURLResponse else {
                    let error = error ?? URLError(.badServerResponse)
                    return continuation.resume(throwing: error)
                }
                
                let isValidStatusCode = (200...299).contains(urlResponse.statusCode)
                
                if isValidStatusCode {
                    continuation.resume(returning: (data, response))
                } else {
                    let e = NetworkError.error(parent: error ?? CBNetworkingError.invalidHTTPStatusCode(data: data), httpStatusCode: urlResponse.statusCode)
                    continuation.resume(throwing: e)
                }
            }

            task.resume()
        }
    }
}
