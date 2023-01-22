import XCTest
@testable import CBNetworking

final class URLRequestBuilderTests: XCTestCase {
    let baseURL = "https//myfakeserver.com/api/v2"
    let endpoint = "articles"
    let multipartData = MultipartData(data: "ciao".data(using: .utf8)!, key: "key", fileName: "filename", mimeType: "mimetype")
    
    func testValidBaseUrl() async throws {
        let sut = getSUT()
        sut.set(path: endpoint)
        let request = try sut.build()
        XCTAssertTrue(request.url!.absoluteString.starts(with: baseURL))
    }
    
    func testValidUrl() async throws {
        let sut = getSUT()
        sut.set(path: endpoint)
        let url = sut.buildURL()!
        let request = try sut.build()
        
        XCTAssertEqual(request.url!.absoluteString, url.absoluteString)
    }
        
    func testHTTPMethod() async throws {
        let sut = getSUT()
        sut.set(path: endpoint)
        sut.set(method: .get)
        let request = try sut.build()
        
        XCTAssertEqual(request.httpMethod, "GET")
    }
    
    func testHeaders() async throws {
        let sut = getSUT()
        sut.set(path: endpoint)
        sut.set(headers: ["Content-Type": "application/json"])
        let request = try sut.build()
        
        XCTAssertEqual(request.allHTTPHeaderFields?.count, 1)
    }
    
    func testQueryItems() async throws {
        let sut = getSUT()
        sut.set(path: endpoint)
        sut.set(queryItems: [URLQueryItem(name: "slug", value: "first-slug")])
        let request = try sut.build()
        
        let urlComponent = URLComponents(url: request.url!, resolvingAgainstBaseURL: true)
        
        XCTAssertEqual(urlComponent?.queryItems?.count, 1)
    }
    
    func testTimeoutInterval() async throws {
        let sut = getSUT()
        sut.set(path: endpoint)
        sut.set(timeoutInterval: 150)
        let request = try sut.build()
        
        XCTAssertEqual(request.timeoutInterval, 150)
    }
    
    func testHTTPBody() async throws {
        let sut = getSUT()
        sut.set(path: endpoint)
        sut.set(httpBody: .raw(data: "ciao".data(using: .utf8)!))
        let request = try sut.build()
        
        XCTAssertEqual(request.httpBody?.count, 4)
    }
    
    func testMultipartHeader() async throws {
        let sut = getSUT()
        sut.set(path: endpoint)
        sut.set(httpBody: .multipart(data: [multipartData]))
        let request = try sut.build()
        
        XCTAssertEqual(request.allHTTPHeaderFields?.count, 1)
    }
    
    func testMultipartBody() async throws {
        let sut = getSUT()
        sut.set(path: endpoint)
        sut.set(httpBody: .multipart(data: [multipartData]))
        let request = try sut.build()
        
        XCTAssertGreaterThan(request.httpBody!.count, 0)
    }
    
    func getSUT() -> URLRequestBuilder {
       URLRequestBuilder(with: URL(string: baseURL)!)
    }
}
