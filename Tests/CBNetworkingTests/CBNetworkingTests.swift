import XCTest
@testable import CBNetworking

final class CBNetworkingTests: XCTestCase {
    
    static var articleData =  #"{"name": "Article 1"}"#.data(using: .utf8)!
    
    func testForEndpointType() async throws {
        MockURLProtocol.data = Self.articleData
        let sut = getSUT()
        let response = try await sut.send(endpoint: .getArticles, type: Article.self)
        XCTAssertEqual(response.model.name, "Article 1")
    }
    
    func testForEndpoint1Type() async throws {
        MockURLProtocol.data = Self.articleData
        let sut = getSUT()
        let response = try await sut.send(endpoint: .postArticle(article: Article(name: "Article 1")), type: Article.self)
        XCTAssertEqual(response.model.name, "Article 1")
    }
    
    func testAdaptedRequest() async throws {
        MockURLProtocol.data = Self.articleData
        let sut = getSUT()
        let request = try sut.getRequest(from: .getArticles)
        XCTAssertEqual(request.allHTTPHeaderFields!.count, 1)
    }
    
    func getSUT() -> CBNetworking<TestEndpoint> {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        let urlSession = URLSession.init(configuration: configuration)
        return CBNetworking(
            urlSession: urlSession,
            adapters: [OAuth2Adapter(bearer: "1234")],
            logger: CurlLogger()
        )
    }
}
