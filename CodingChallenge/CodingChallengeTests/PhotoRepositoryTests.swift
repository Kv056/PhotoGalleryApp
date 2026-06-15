import CoreData
import XCTest
@testable import CodingChallenge

@MainActor
final class PhotoRepositoryTests: XCTestCase {
    private var coreDataStack: TestCoreDataStack!

    override func setUp() async throws {
        try await super.setUp()
        coreDataStack = TestCoreDataStack()
    }

    override func tearDown() async throws {
        coreDataStack = nil
        try await super.tearDown()
    }

    func test_loadPhotosIfNeeded_whenStoreEmpty_fetchesAndSaves() async throws {
        let mockAPI = MockPhotoAPIService()
        mockAPI.photosToReturn = [
            PhotoTestFactory.makeDTO(id: 1),
            PhotoTestFactory.makeDTO(id: 2)
        ]

        let repository = coreDataStack.makeRepository(apiService: mockAPI)
        try await repository.loadPhotosIfNeeded(onFirstBatchSaved: nil)

        XCTAssertEqual(mockAPI.fetchCallCount, 1)
        XCTAssertEqual(try repository.photoCount(), 2)
    }

    func test_loadPhotosIfNeeded_whenStoreHasData_skipsAPI() async throws {
        _ = PhotoTestFactory.makePhoto(in: coreDataStack.viewContext, id: 1)
        try coreDataStack.viewContext.save()

        let mockAPI = MockPhotoAPIService()
        mockAPI.photosToReturn = [PhotoTestFactory.makeDTO(id: 99)]

        let repository = coreDataStack.makeRepository(apiService: mockAPI)
        try await repository.loadPhotosIfNeeded(onFirstBatchSaved: nil)

        XCTAssertEqual(mockAPI.fetchCallCount, 0)
        XCTAssertEqual(try repository.photoCount(), 1)
        XCTAssertEqual(try repository.photo(with: 1)?.title, "Test photo")
    }

    func test_loadPhotosIfNeeded_upsert_doesNotDuplicateExistingId() async throws {
        let dto = PhotoTestFactory.makeDTO(id: 1, title: "Original")
        let mockAPI = MockPhotoAPIService()
        mockAPI.photosToReturn = [dto]

        let repository = coreDataStack.makeRepository(apiService: mockAPI)
        try await repository.loadPhotosIfNeeded(onFirstBatchSaved: nil)

        mockAPI.photosToReturn = [PhotoTestFactory.makeDTO(id: 1, title: "Updated")]
        try await repository.loadPhotosIfNeeded(onFirstBatchSaved: nil)

        XCTAssertEqual(mockAPI.fetchCallCount, 1)
        XCTAssertEqual(try repository.photoCount(), 1)
        XCTAssertEqual(try repository.photo(with: 1)?.title, "Original")
    }

    func test_fetchPage_returnsPhotosSortedByIdAscending() async throws {
        let mockAPI = MockPhotoAPIService()
        mockAPI.photosToReturn = [
            PhotoTestFactory.makeDTO(id: 3),
            PhotoTestFactory.makeDTO(id: 1),
            PhotoTestFactory.makeDTO(id: 2)
        ]

        let repository = coreDataStack.makeRepository(apiService: mockAPI)
        try await repository.loadPhotosIfNeeded(onFirstBatchSaved: nil)

        let page = try repository.fetchPage(offset: 0, limit: 3)
        XCTAssertEqual(page.map(\.id), [1, 2, 3])
    }

    func test_fetchPage_respectsOffsetAndLimit() async throws {
        let mockAPI = MockPhotoAPIService()
        mockAPI.photosToReturn = (1...5).map { PhotoTestFactory.makeDTO(id: $0) }

        let repository = coreDataStack.makeRepository(apiService: mockAPI)
        try await repository.loadPhotosIfNeeded(onFirstBatchSaved: nil)

        let page = try repository.fetchPage(offset: 2, limit: 2)
        XCTAssertEqual(page.count, 2)
        XCTAssertEqual(page.map(\.id), [3, 4])
    }

    func test_updateTitle_persistsNewTitle() async throws {
        let photo = PhotoTestFactory.makePhoto(in: coreDataStack.viewContext, id: 1, title: "Old title")
        try coreDataStack.viewContext.save()

        let repository = coreDataStack.makeRepository()
        try repository.updateTitle(id: photo.id, title: "New title")

        let updated = try repository.photo(with: 1)
        XCTAssertEqual(updated?.title, "New title")
    }

    func test_updateTitle_notFound_throwsNotFound() async {
        let repository = coreDataStack.makeRepository()

        XCTAssertThrowsError(try repository.updateTitle(id: 999, title: "Missing")) { error in
            XCTAssertEqual(error as? RepositoryError, .notFound)
        }
    }

    func test_deletePhoto_removesFromCoreData() async throws {
        _ = PhotoTestFactory.makePhoto(in: coreDataStack.viewContext, id: 1)
        try coreDataStack.viewContext.save()

        let repository = coreDataStack.makeRepository()
        try repository.deletePhoto(id: 1)

        XCTAssertEqual(try repository.photoCount(), 0)
        XCTAssertNil(try repository.photo(with: 1))
    }

    func test_deletePhoto_notFound_throwsNotFound() async {
        let repository = coreDataStack.makeRepository()

        XCTAssertThrowsError(try repository.deletePhoto(id: 999)) { error in
            XCTAssertEqual(error as? RepositoryError, .notFound)
        }
    }

    func test_photoCount_returnsCorrectCount() async throws {
        _ = PhotoTestFactory.seedPhotos(in: coreDataStack.viewContext, count: 4)
        try coreDataStack.viewContext.save()

        let repository = coreDataStack.makeRepository()
        XCTAssertEqual(try repository.photoCount(), 4)
    }
}

extension RepositoryError: Equatable {}
