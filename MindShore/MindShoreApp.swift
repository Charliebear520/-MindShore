//
//  MindShoreApp.swift
//  MindShore
//
//  Created by 黃塏峻 on 2025/5/19.
//

import SwiftUI

@main
struct MindShoreApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
