import Foundation

/// A custom logger class used to log the request as cURL.
public class CurlLogger: Loggable {
   
    public init() {}
    
    /// The log method.
    public func log(request: URLRequest) -> String {
        guard let url = request.url else { return "" }
        var baseCommand = "curl \(url.absoluteString)"

        if request.httpMethod == "HEAD" {
            baseCommand += " --head"
        }

        var command = [baseCommand]

        if let method = request.httpMethod, method != "GET", method != "HEAD" {
            command.append("-X \(method)")
        }

        if let headers = request.allHTTPHeaderFields {
            for (key, value) in headers where key != "Cookie" {
                command.append("-H '\(key): \(value)'")
            }
        }

        if let data = request.httpBody, let body = String(data: data, encoding: .utf8) {
            command.append("-d '\(body)'")
        }

        return command.joined(separator: " \\\n\t")
    }
    
    public func log(error: Error) -> String? {
        print(error.localizedDescription)
    }
}
