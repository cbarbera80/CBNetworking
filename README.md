# CBNetworking

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a>
    <img src="Sources/Resources/network.png" alt="Logo" width="120" height="120">
  </a>

  <h3 align="center">CBNetworking</h3>
</div>

CBNetworking is a lightweight library that allows interfacing with the HTTP Rest APIs. 

# How to install

## Swift Package Manager

Add the following dependency to your Package.swift:

```swift
dependencies: [
  .package(url: "https://github.com/cbarbera80/CBNetworking.git", .upToNextMajor(from: "1.0.0"))
]
```

Or add the dependency to your app using Xcode: File => Swift Packages => Add Package Dependency... and type the git repo url: https://github.com/cbarbera80/CBNetworking.git

# Requirements

* iOS 13.0+ / macOS 10.15+ / watchOS 5.0+
* Swift 5.2+
* Xcode 11.4+

# How to use

First, you must to create an instance of `CBNetworking`. The default `init` method doesn't require any parameters, but you can optional provide a `JSONDecoder` used to decode the response. You can also provide a list of `RequestAdapter` to adapt the request with your custom logics. The `init` method can optional accept a logger parameter: this must be a class that implement the `Loggable` protocol.

```swift
var networking = CBNetworking<TestEndpoint>()
```

or 
```swift
var networking = CBNetworking<TestEndpoint>(decoder: decoder, adapters: [OAuth2Adapter()], logger: CurlLogger())
```

Then you must create an enum that describe the structure of your API:

```swift

enum TestEndpoint {
    case getArticle(id: Int)
}

extension TestEndpoint: EndpointType {
    
    var headers: [String : Any]? {
        nil
    }
    
    var baseURL: URL {
        return URL(string: "yourapibaseurl")!
    }
    
    var path: String {
        switch self {
        case .getArticle(let id):
            return "articles/\(id)"
        }
    }
    
    var queryItems: [URLQueryItem]? {
        return nil
    }
    
    var method: HTTPMethod {
        return .get
    }
    
    var httpBody: HTTPBodyType? {
        return nil
    }
}
```

Then you can make the network call:

```swift
let article: Article = try await networking.send(endpoint: .getArticle(id: 1))
```

# How to use a RequestAdapter

The library allows you to inject a list of adapters which will be used to shape your request:

```swift
class OAuth2Adapter: RequestAdapter {
    func adapt(_ request: URLRequest) -> URLRequest {
        var request = request
        request.addValue("Authorization", forHTTPHeaderField: "Bearer ...")
        return request
    }
}
```

# How to use a Logger

The library allows you to define a custom logger used to print the request in the console.
The library comes with a logger already defined, `CurlLogger()`, but you can create your own logger by creating your own class which implements the `Loggable` protocol:

```swift
class CustomLogger: Loggable {
    func log(request: URLRequest) -> String {
        print(request)
    }
}
```
