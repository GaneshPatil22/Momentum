//
//  MomentumApp.swift
//  Momentum
//
//  Created by Ganesh Patil on 24/06/26.
//

import SwiftUI
import SwiftData

@main
struct MomentumApp: App {
    let container: ModelContainer
    let activityService: ActivityService

    init() {
        do {
            container = try ModelContainer(for: Initiative.self, TaskItem.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        activityService = ActivityService(context: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
        .environment(activityService)
    }
}
