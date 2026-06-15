//
//  PhotoDTO.swift
//  CodingChallenge
//
//  Created by Kirtan on 6/14/26.
//

import CoreData
import Foundation

protocol PhotoRepositoryProtocol {
    func photoCount() throws -> Int
    func loadPhotosIfNeeded(onFirstBatchSaved: (() async throws -> Void)?) async throws
    func fetchPage(offset: Int, limit: Int) throws -> [Photo]
    func updateTitle(id: Int64, title: String) throws
    func deletePhoto(id: Int64) throws
    func photo(with id: Int64) throws -> Photo?
}

final class PhotoRepository: PhotoRepositoryProtocol {
    static let pageSize = 30
    static let saveBatchSize = 50

    private let context: NSManagedObjectContext
    private let apiService: PhotoAPIServiceProtocol

    init(context: NSManagedObjectContext, apiService: PhotoAPIServiceProtocol = PhotoAPIService()) {
        self.context = context
        self.apiService = apiService
    }

    func photoCount() throws -> Int {
        let request = Photo.fetchRequest()
        return try context.count(for: request)
    }

    func loadPhotosIfNeeded(onFirstBatchSaved: (() async throws -> Void)? = nil) async throws {
        let count = try photoCount()
        guard count == 0 else { return }

        let dtos = try await apiService.fetchPhotos()
        var isFirstBatch = true

        for batchStart in stride(from: 0, to: dtos.count, by: Self.saveBatchSize) {
            let endIndex = min(batchStart + Self.saveBatchSize, dtos.count)
            let batch = Array(dtos[batchStart..<endIndex])
            try savePhotos(batch)

            if isFirstBatch {
                try await onFirstBatchSaved?()
                isFirstBatch = false
            }

            await Task.yield()
        }
    }

    func fetchPage(offset: Int, limit: Int) throws -> [Photo] {
        let request = Photo.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Photo.id, ascending: true)]
        request.fetchOffset = offset
        request.fetchLimit = limit

        do {
            return try context.fetch(request)
        } catch {
            throw RepositoryError.fetchFailed
        }
    }

    func updateTitle(id: Int64, title: String) throws {
        guard let photo = try photo(with: id) else {
            throw RepositoryError.notFound
        }

        photo.title = title

        do {
            try context.save()
        } catch {
            context.rollback()
            throw RepositoryError.saveFailed
        }
    }

    func deletePhoto(id: Int64) throws {
        guard let photo = try photo(with: id) else {
            throw RepositoryError.notFound
        }

        context.delete(photo)

        do {
            try context.save()
        } catch {
            context.rollback()
            throw RepositoryError.deleteFailed
        }
    }

    func photo(with id: Int64) throws -> Photo? {
        let request = Photo.fetchRequest()
        request.predicate = NSPredicate(format: "id == %lld", id)
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            throw RepositoryError.fetchFailed
        }
    }

    private func savePhotos(_ dtos: [PhotoDTO]) throws {
        for dto in dtos {
            let photo = (try photo(with: Int64(dto.id))) ?? Photo(context: context)
            photo.id = Int64(dto.id)
            photo.albumId = Int64(dto.albumId)
            photo.title = dto.title
            photo.url = dto.url
            photo.thumbnailUrl = dto.thumbnailUrl
        }

        do {
            try context.save()
        } catch {
            context.rollback()
            throw RepositoryError.saveFailed
        }
    }
}
