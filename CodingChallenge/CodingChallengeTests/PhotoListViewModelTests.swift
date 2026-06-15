import CoreData
import XCTest
@testable import CodingChallenge

@MainActor
final class PhotoListViewModelTests: XCTestCase {
    private var coreDataStack: TestCoreDataStack!
    private var mockRepository: MockPhotoRepository!
    private var viewModel: PhotoListViewModel!

    override func setUp() async throws {
        try await super.setUp()
        coreDataStack = TestCoreDataStack()
        mockRepository = MockPhotoRepository()
        viewModel = PhotoListViewModel(repository: mockRepository)
    }

    override func tearDown() async throws {
        viewModel = nil
        mockRepository = nil
        coreDataStack = nil
        try await super.tearDown()
    }

    func test_loadInitial_populatesFirstPage() async {
        mockRepository.storedPhotos = PhotoTestFactory.seedPhotos(in: coreDataStack.viewContext, count: 50)
        mockRepository.totalCount = 50

        await viewModel.loadInitial()

        XCTAssertEqual(viewModel.photos.count, 30)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.hasMorePages)
    }

    func test_loadInitial_doesNotAutoLoadAllPages() async {
        mockRepository.storedPhotos = PhotoTestFactory.seedPhotos(in: coreDataStack.viewContext, count: 90)
        mockRepository.totalCount = 90

        await viewModel.loadInitial()

        XCTAssertEqual(viewModel.photos.count, 30)
        XCTAssertTrue(viewModel.hasMorePages)
    }

    func test_loadInitial_clearsErrorOnSuccess() async {
        viewModel.errorMessage = "Previous error"
        mockRepository.storedPhotos = PhotoTestFactory.seedPhotos(in: coreDataStack.viewContext, count: 5)
        mockRepository.totalCount = 5

        await viewModel.loadInitial()

        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.photos.count, 5)
    }

    func test_loadInitial_onFailure_setsErrorMessage() async {
        mockRepository.errorToThrow = NetworkError.requestFailed(statusCode: 500)

        await viewModel.loadInitial()

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.photos.isEmpty)
    }

    func test_isEmpty_trueWhenNoPhotosAndNotLoading() async {
        mockRepository.errorToThrow = NetworkError.noData

        await viewModel.loadInitial()

        XCTAssertTrue(viewModel.isEmpty)
    }

    func test_loadMore_appendsNextPage() async {
        mockRepository.storedPhotos = PhotoTestFactory.seedPhotos(in: coreDataStack.viewContext, count: 60)
        mockRepository.totalCount = 60

        await viewModel.loadInitial()
        XCTAssertEqual(viewModel.photos.count, 30)

        await viewModel.loadMore()

        XCTAssertEqual(viewModel.photos.count, 60)
    }

    func test_deletePendingPhoto_removesFromPublishedList() async {
        let photos = PhotoTestFactory.seedPhotos(in: coreDataStack.viewContext, count: 2)
        mockRepository.storedPhotos = photos
        mockRepository.totalCount = 2

        await viewModel.loadInitial()
        let photoToDelete = viewModel.photos.first!

        viewModel.confirmDelete(photoToDelete)
        viewModel.deletePendingPhoto()

        XCTAssertEqual(viewModel.photos.count, 1)
        XCTAssertNil(viewModel.photoPendingDeletion)
        XCTAssertEqual(mockRepository.deletePhotoCallCount, 1)
    }

    func test_refreshAfterEdit_updatesPhotoTitleInList() async {
        let photos = PhotoTestFactory.seedPhotos(in: coreDataStack.viewContext, count: 3)
        mockRepository.storedPhotos = photos
        mockRepository.totalCount = 3

        await viewModel.loadInitial()
        let photoID = viewModel.photos[1].id

        viewModel.refreshAfterEdit(for: photoID, title: "Updated list title")

        XCTAssertEqual(viewModel.photos[1].title, "Updated list title")
    }
}
