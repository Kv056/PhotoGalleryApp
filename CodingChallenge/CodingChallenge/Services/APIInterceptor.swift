import Foundation

protocol APIInterceptorProtocol: Sendable {
    func adapt(_ request: URLRequest) async throws -> URLRequest
}

final class APIInterceptor: APIInterceptorProtocol {
    func adapt(_ request: URLRequest) async throws -> URLRequest {
        var adaptedRequest = request
        adaptedRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        return adaptedRequest
    }
}
