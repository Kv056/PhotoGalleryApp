import CoreData
import XCTest
@testable import CodingChallenge

@MainActor
final class PhotoDetailViewModelTests: XCTestCase {
    private var coreDataStack: TestCoreDataStack!
    private var mockRepository: MockPhotoRepository!
    private var photo: Photo!

    override func setUp() async throws {
        try await super.setUp()
        coreDataStack = TestCoreDataStack()
        mockRepository = MockPhotoRepository()
        photo = PhotoTestFactory.makePhoto(in: coreDataStack.viewContext, id: 1, title: "Original title")
        mockRepository.storedPhotos = [photo]
        mockRepository.totalCount = 1
    }

    override func tearDown() async throws {
        photo = nil
        mockRepository = nil
        coreDataStack = nil
        try await super.tearDown()
    }

    func test_hasChanges_trueWhenTitleModified() async {
        let viewModel = makeViewModel()

        viewModel.title = "Updated title"

        XCTAssertTrue(viewModel.hasChanges)
    }

    func test_hasChanges_falseWhenTitleMatchesOriginal() async {
        let viewModel = makeViewModel()

        XCTAssertFalse(viewModel.hasChanges)
    }

    func test_save_emptyTitle_setsErrorAndReturnsFalse() async {
        let viewModel = makeViewModel()
        viewModel.title = "   "

        let didSave = viewModel.save()

        XCTAssertFalse(didSave)
        XCTAssertEqual(viewModel.errorMessage, "Title cannot be empty.")
        XCTAssertEqual(mockRepository.updateTitleCallCount, 0)
    }

    func test_save_validTitle_updatesAndCallsOnSave() async {
        var savedTitle: String?
        let viewModel = PhotoDetailViewModel(
            photo: photo,
            repository: mockRepository,
            onSave: { savedTitle = $0 },
            onDelete: {}
        )
        viewModel.title = "Updated title"

        let didSave = viewModel.save()

        XCTAssertTrue(didSave)
        XCTAssertEqual(savedTitle, "Updated title")
        XCTAssertEqual(photo.title, "Updated title")
        XCTAssertEqual(mockRepository.updateTitleCallCount, 1)
        XCTAssertEqual(mockRepository.lastUpdatedTitle, "Updated title")
    }

    func test_deletePhoto_success_callsOnDeleteAndReturnsTrue() async {
        var didCallOnDelete = false
        let viewModel = PhotoDetailViewModel(
            photo: photo,
            repository: mockRepository,
            onSave: { _ in },
            onDelete: { didCallOnDelete = true }
        )

        let didDelete = viewModel.deletePhoto()

        XCTAssertTrue(didDelete)
        XCTAssertTrue(didCallOnDelete)
        XCTAssertEqual(mockRepository.deletePhotoCallCount, 1)
        XCTAssertEqual(mockRepository.lastDeletedPhotoID, 1)
    }

    private func makeViewModel(
        onSave: @escaping (String) -> Void = { _ in },
        onDelete: @escaping () -> Void = {}
    ) -> PhotoDetailViewModel {
        PhotoDetailViewModel(
            photo: photo,
            repository: mockRepository,
            onSave: onSave,
            onDelete: onDelete
        )
    }
}
