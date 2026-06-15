import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

struct Endpoint {
    let path: String
    let method: HTTPMethod
    let headers: [String: String]?
    let body: Data?

    init(path: String, method: HTTPMethod = .get, headers: [String: String]? = nil, body: Data? = nil) {
        self.path = path
        self.method = method
        self.headers = headers
        self.body = body
    }
}

extension Endpoint {
    static let photos = Endpoint(path: APIConstants.photosEndpointPath)
}
