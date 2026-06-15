import Foundation

enum APIConstants {
    static let baseURL = "https://jsonplaceholder.typicode.com"
    static let photosEndpointPath = "/photos"

    static func makeURL(path: String) -> URL? {
        URL(string: baseURL + path)
    }
}
