//
//  PhotoDTO.swift
//  CodingChallenge
//
//  Created by Kirtan on 6/14/26.
//

import CoreData
import SDWebImageSwiftUI
import SwiftUI

struct PhotoDetailView: View {
    @StateObject private var viewModel: PhotoDetailViewModel
    @Environment(\.presentationMode) private var presentationMode

    init(
        photo: Photo,
        repository: PhotoRepositoryProtocol,
        onSave: @escaping (String) -> Void,
        onDelete: @escaping () -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: PhotoDetailViewModel(
                photo: photo,
                repository: repository,
                onSave: onSave,
                onDelete: onDelete
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                WebImage(url: URL(string: viewModel.photo.url ?? "")) { image in
                    image.resizable()
                } placeholder: {
                    PhotoPlaceholderImage()
                }
                .indicator(.activity)
                .transition(.fade(duration: 0.2))
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Photo title", text: $viewModel.title)
                        .textFieldStyle(.roundedBorder)
                }

                Button("Save") {
                    if viewModel.save() {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.hasChanges)

                Button("Delete Photo") {
                    viewModel.showDeleteConfirmation = true
                }
                .foregroundColor(.red)
            }
            .padding()
        }
        .navigationTitle("Edit Photo")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: errorAlertBinding) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage ?? "Something went wrong."),
                dismissButton: .cancel {
                    viewModel.errorMessage = nil
                }
            )
        }
        .alert(isPresented: $viewModel.showDeleteConfirmation) {
            Alert(
                title: Text("Delete Photo"),
                message: Text("Are you sure you want to delete this photo?"),
                primaryButton: .destructive(Text("Delete")) {
                    if viewModel.deletePhoto() {
                        presentationMode.wrappedValue.dismiss()
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}

#Preview {
    NavigationView {
        PhotoDetailView(
            photo: {
                let context = PersistenceController.preview.container.viewContext
                let photo = Photo(context: context)
                photo.id = 1
                photo.albumId = 1
                photo.title = "Sample photo"
                photo.url = "https://via.placeholder.com/600"
                photo.thumbnailUrl = "https://via.placeholder.com/150"
                return photo
            }(),
            repository: PhotoRepository(context: PersistenceController.preview.container.viewContext),
            onSave: { _ in },
            onDelete: {}
        )
    }
}
