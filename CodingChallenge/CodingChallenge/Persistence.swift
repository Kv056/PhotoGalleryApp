//
//  Persistence.swift
//  CodingChallenge
//

import CoreData
import os.log

struct PersistenceController {
    static let shared = PersistenceController()

    private static let logger = Logger(subsystem: "Kirtan.CodingChallenge", category: "Persistence")

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        for index in 1...5 {
            let photo = Photo(context: viewContext)
            photo.id = Int64(index)
            photo.albumId = 1
            photo.title = "Preview photo \(index)"
            photo.url = "https://via.placeholder.com/600"
            photo.thumbnailUrl = "https://via.placeholder.com/150"
        }

        do {
            try viewContext.save()
        } catch {
            logger.error("Preview save failed: \(error.localizedDescription)")
        }

        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "CodingChallenge")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error {
                Self.logger.error("Core Data store failed to load: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
