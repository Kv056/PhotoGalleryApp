//
//  PhotoDTO.swift
//  CodingChallenge
//
//  Created by Kirtan on 6/14/26.
//

import Foundation

protocol PhotoAPIServiceProtocol: Sendable {
    func fetchPhotos() async throws -> [PhotoDTO]
}

final class PhotoAPIService: PhotoAPIServiceProtocol {
    private let client: APIClientProtocol

    init(client: APIClientProtocol = APIClient.shared) {
        self.client = client
    }

    func fetchPhotos() async throws -> [PhotoDTO] {
        try await client.request(Endpoint.photos, responseType: [PhotoDTO].self)
    }
}
