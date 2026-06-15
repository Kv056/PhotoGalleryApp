import Foundation
@testable import CodingChallenge

final class MockPhotoAPIService: PhotoAPIServiceProtocol, @unchecked Sendable {
    var photosToReturn: [PhotoDTO] = []
    var errorToThrow: Error?
    private(set) var fetchCallCount = 0

    func fetchPhotos() async throws -> [PhotoDTO] {
        fetchCallCount += 1

        if let errorToThrow {
            throw errorToThrow
        }

        return photosToReturn
    }
}
