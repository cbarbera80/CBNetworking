import Foundation
import CBNetworking

struct PageData: Encodable {
    let limit: Int
    let page: Int
}

enum TestEndpoint {
    case getArticle(id: Int)
    case getArticles
    case searchArticles(slug: String, pageData: PageData)
    case postArticle(article: Article)
}

extension TestEndpoint: EndpointType {
    var shouldRetryOnFailure: Bool {
        false
    }
    
    var headers: [String : Any]? {
        nil
    }
    
    var baseURL: URL {
        return URL(string: "https://fakebackend/api/v1")!
    }
    
    var path: String {
        switch self {
        case .getArticles:
            return "articles"
        case .getArticle(let id):
            return "articles/\(id)"
        case .searchArticles:
            return "articles/search"
        case .postArticle:
            return "articles"
        }
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .getArticle, .getArticles, .postArticle:
            return nil
        case .searchArticles(let slug, _):
            return [URLQueryItem(name: "slug", value: slug)]
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .getArticle, .getArticles  :
            return .get
        case .searchArticles, .postArticle:
            return .post
        }
    }
    
    var httpBody: HTTPBodyType? {
        switch self {
        case .getArticle, .getArticles:
            return nil
        case .searchArticles(_, let pageData):
            return .jsonEncodable(data: pageData)
        case .postArticle(let article):
            return .multipart(data: [MultipartData(data: "ciao".data(using: .utf8)!, key: "key", fileName: "article_\(article.name)", mimeType: "mimetype")])
        }
    }
}
