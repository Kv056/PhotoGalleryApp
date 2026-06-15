//
//  PhotoDTO.swift
//  CodingChallenge
//
//  Created by Kirtan on 6/14/26.
//

import Combine
import CoreData
import Foundation

@MainActor
final class PhotoListViewModel: ObservableObject {
    @Published private(set) var photos: [Photo] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMorePages = false
    @Published var errorMessage: String?
    @Published var photoPendingDeletion: Photo?

    private let repository: PhotoRepositoryProtocol
    private var currentOffset = 0
    private var totalCount = 0

    init(repository: PhotoRepositoryProtocol) {
        self.repository = repository
    }

    var isEmpty: Bool {
        photos.isEmpty && !isLoading
    }

    func loadInitial() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        photos = []
        currentOffset = 0
        hasMorePages = false

        do {
            var didShowFirstPage = false

            try await repository.loadPhotosIfNeeded { [weak self] in
                guard let self else { return }
                try await self.displayFirstPageIfNeeded()
                didShowFirstPage = true
                self.isLoading = false
            }

            totalCount = try repository.photoCount()

            if !didShowFirstPage {
                try await displayFirstPageIfNeeded()
            } else {
                hasMorePages = currentOffset < totalCount
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func retry() async {
        await loadInitial()
    }

    func loadMore() async {
        guard hasMorePages, !isLoadingMore, !isLoading else { return }

        isLoadingMore = true

        do {
            try await loadNextPage(isInitial: false)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoadingMore = false
    }

    func confirmDelete(_ photo: Photo) {
        photoPendingDeletion = photo
    }

    func deletePendingPhoto() {
        guard let photo = photoPendingDeletion else { return }

        do {
            try repository.deletePhoto(id: photo.id)
            photos.removeAll { $0.objectID == photo.objectID }
            totalCount = max(0, totalCount - 1)
            hasMorePages = currentOffset < totalCount
            photoPendingDeletion = nil
        } catch {
            errorMessage = error.localizedDescription
            photoPendingDeletion = nil
        }
    }

    func removePhoto(_ photo: Photo) {
        photos.removeAll { $0.objectID == photo.objectID }
        totalCount = max(0, totalCount - 1)
        hasMorePages = currentOffset < totalCount
    }

    func refreshAfterEdit(for photoID: Int64, title: String) {
        guard let index = photos.firstIndex(where: { $0.id == photoID }) else { return }

        photos[index].title = title
        photos = Array(photos)
    }

    private func displayFirstPageIfNeeded() async throws {
        guard photos.isEmpty else { return }

        totalCount = try repository.photoCount()
        try await loadNextPage(isInitial: true)
    }

    private func loadNextPage(isInitial: Bool) async throws {
        guard currentOffset < totalCount else {
            hasMorePages = false
            return
        }

        let page = try repository.fetchPage(offset: currentOffset, limit: PhotoRepository.pageSize)

        if isInitial {
            photos = page
        } else {
            photos.append(contentsOf: page)
        }

        currentOffset += page.count
        hasMorePages = currentOffset < totalCount
    }
}
