//
//  CodingChallengeApp.swift
//  CodingChallenge
//

import SwiftUI
import CoreData

@main
struct CodingChallengeApp: App {
    let persistenceController = PersistenceController.shared

    private var isRunningUnitTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    var body: some Scene {
        WindowGroup {
            if isRunningUnitTests {
                EmptyView()
            } else {
                PhotoListView(
                    repository: PhotoRepository(context: persistenceController.container.viewContext)
                )
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
    }
}
