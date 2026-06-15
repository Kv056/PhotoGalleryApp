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
final class PhotoDetailViewModel: ObservableObject {
    @Published var title: String
    @Published var errorMessage: String?
    @Published var showDeleteConfirmation = false

    let photo: Photo
    private let repository: PhotoRepositoryProtocol
    private let onSave: (String) -> Void
    private let onDelete: () -> Void

    init(
        photo: Photo,
        repository: PhotoRepositoryProtocol,
        onSave: @escaping (String) -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.photo = photo
        self.repository = repository
        self.onSave = onSave
        self.onDelete = onDelete
        self.title = photo.title ?? ""
    }

    var hasChanges: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines) != (photo.title ?? "")
    }

    func save() -> Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            errorMessage = "Title cannot be empty."
            return false
        }

        do {
            try repository.updateTitle(id: photo.id, title: trimmedTitle)
            photo.title = trimmedTitle
            onSave(trimmedTitle)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func deletePhoto() -> Bool {
        do {
            try repository.deletePhoto(id: photo.id)
            onDelete()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
