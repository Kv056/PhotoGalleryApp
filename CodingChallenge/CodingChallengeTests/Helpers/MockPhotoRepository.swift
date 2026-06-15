import CoreData
import Foundation
@testable import CodingChallenge

final class MockPhotoRepository: PhotoRepositoryProtocol {
    var storedPhotos: [Photo] = []
    var totalCount = 0
    var errorToThrow: Error?
    var loadPhotosIfNeededCallCount = 0
    var deletePhotoCallCount = 0
    var updateTitleCallCount = 0
    var lastUpdatedTitle: String?
    var lastDeletedPhotoID: Int64?

    func photoCount() throws -> Int {
        if let errorToThrow { throw errorToThrow }
        return totalCount
    }

    func loadPhotosIfNeeded(onFirstBatchSaved: (() async throws -> Void)? = nil) async throws {
        loadPhotosIfNeededCallCount += 1
        if let errorToThrow { throw errorToThrow }
        try await onFirstBatchSaved?()
    }

    func fetchPage(offset: Int, limit: Int) throws -> [Photo] {
        if let errorToThrow { throw errorToThrow }

        let sorted = storedPhotos.sorted { $0.id < $1.id }
        guard offset < sorted.count else { return [] }
        let end = min(offset + limit, sorted.count)
        return Array(sorted[offset..<end])
    }

    func updateTitle(id: Int64, title: String) throws {
        updateTitleCallCount += 1
        lastUpdatedTitle = title

        if let errorToThrow { throw errorToThrow }

        guard let photo = storedPhotos.first(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }

        photo.title = title
    }

    func deletePhoto(id: Int64) throws {
        deletePhotoCallCount += 1
        lastDeletedPhotoID = id

        if let errorToThrow { throw errorToThrow }

        guard let index = storedPhotos.firstIndex(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }

        storedPhotos.remove(at: index)
        totalCount = storedPhotos.count
    }

    func photo(with id: Int64) throws -> Photo? {
        if let errorToThrow { throw errorToThrow }
        return storedPhotos.first { $0.id == id }
    }
}
