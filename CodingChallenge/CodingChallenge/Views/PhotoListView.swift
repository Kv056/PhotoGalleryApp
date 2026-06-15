//
//  PhotoDTO.swift
//  CodingChallenge
//
//  Created by Kirtan on 6/14/26.
//

import CoreData
import SwiftUI

struct PhotoListView: View {
    @StateObject private var viewModel: PhotoListViewModel
    private let repository: PhotoRepositoryProtocol

    init(repository: PhotoRepositoryProtocol? = nil) {
        let repository = repository ?? PhotoRepository(context: PersistenceController.shared.container.viewContext)
        self.repository = repository
        _viewModel = StateObject(wrappedValue: PhotoListViewModel(repository: repository))
    }

    var body: some View {
        NavigationView {
            content
                .navigationTitle("Photos")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if viewModel.errorMessage != nil {
                            Button("Retry") {
                                Task { await viewModel.retry() }
                            }
                        }
                    }
                }
                .alert(isPresented: deleteAlertBinding) {
                    Alert(
                        title: Text("Delete Photo"),
                        message: Text("Are you sure you want to delete this photo?"),
                        primaryButton: .destructive(Text("Delete")) {
                            viewModel.deletePendingPhoto()
                        },
                        secondaryButton: .cancel {
                            viewModel.photoPendingDeletion = nil
                        }
                    )
                }
                .alert(isPresented: errorAlertBinding) {
                    Alert(
                        title: Text("Error"),
                        message: Text(viewModel.errorMessage ?? "Something went wrong."),
                        primaryButton: .default(Text("Retry")) {
                            Task { await viewModel.retry() }
                        },
                        secondaryButton: .cancel {
                            viewModel.errorMessage = nil
                        }
                    )
                }
                .task {
                    await viewModel.loadInitial()
                }
        }
        .navigationViewStyle(.stack)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.photos.isEmpty {
            ProgressView("Loading photos…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.isEmpty {
            EmptyStateView(
                message: viewModel.errorMessage ?? "No photos available.",
                systemImage: "photo.on.rectangle.angled"
            )
        } else {
            photoList
        }
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.photoPendingDeletion != nil },
            set: { if !$0 { viewModel.photoPendingDeletion = nil } }
        )
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil && !viewModel.isEmpty },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }

    private var photoList: some View {
        List {
            if let errorMessage = viewModel.errorMessage, !viewModel.photos.isEmpty {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
            }

            ForEach(viewModel.photos, id: \.objectID) { photo in
                NavigationLink {
                    PhotoDetailView(
                        photo: photo,
                        repository: repository,
                        onSave: { viewModel.refreshAfterEdit(for: photo.id, title: $0) },
                        onDelete: { viewModel.removePhoto(photo) }
                    )
                } label: {
                    PhotoRowView(photo: photo)
                        .id("\(photo.id)-\(photo.title ?? "")")
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        viewModel.confirmDelete(photo)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }

            if viewModel.hasMorePages {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
                .onAppear {
                    Task { await viewModel.loadMore() }
                }
            }
        }
        .listStyle(.plain)
    }
}

#Preview {
    PhotoListView(
        repository: PhotoRepository(context: PersistenceController.preview.container.viewContext)
    )
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
