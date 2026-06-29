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
    @Environment(\.scenePhase) private var scenePhase

    let container: ModelContainer
    let activityService: ActivityService
    let syncStatus: SyncStatusService
    let archiveService: ArchiveService
    let notificationService: NotificationService
    let router: AppRouter
    let aiAssist: AIAssistService

    init() {
        let schema = Schema([Initiative.self, TaskItem.self])
        var cloudKitActive = false
        let resolved: ModelContainer

        do {
            // Prefer a CloudKit-backed store. `.automatic` resolves the container
            // from the iCloud entitlement; without it (or if CloudKit is otherwise
            // unavailable) this throws and we fall back to a local store.
            let cloudConfig = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
            resolved = try ModelContainer(for: schema, configurations: cloudConfig)
            cloudKitActive = true
        } catch {
            do {
                let localConfig = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
                resolved = try ModelContainer(for: schema, configurations: localConfig)
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }

        container = resolved
        activityService = ActivityService(context: container.mainContext)
        syncStatus = SyncStatusService(cloudKitActive: cloudKitActive)
        archiveService = ArchiveService(context: container.mainContext)
        notificationService = NotificationService(context: container.mainContext)
        router = AppRouter(context: container.mainContext)
        aiAssist = AIAssistService()

        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-seedSampleData") {
            SampleData.seed(into: container.mainContext)
            UserDefaults.standard.set(true, forKey: SettingsKey.hasOnboarded)
        }
        #endif

        // Notification taps deep-link into the matching initiative.
        let router = router
        notificationService.onOpenInitiative = { id in router.openInitiative(id: id) }

        // Register the daily background sweep (no-ops cleanly if the BG identifier
        // isn't declared in Info.plist yet — see BackgroundRefresh).
        let archiveService = archiveService
        let notificationService = notificationService
        BackgroundRefresh.register {
            archiveService.sweep()
            notificationService.sweepColdNotifications()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(router)
                .task { await notificationService.requestAuthorization() }
                .onChange(of: scenePhase, initial: true) { _, phase in
                    switch phase {
                    case .active:
                        // Catch up on archiving + cold nudges every time the app comes forward.
                        archiveService.sweep()
                        notificationService.sweepColdNotifications()
                    case .background:
                        BackgroundRefresh.schedule()
                    default:
                        break
                    }
                }
        }
        .modelContainer(container)
        .environment(activityService)
        .environment(syncStatus)
        .environment(archiveService)
        .environment(aiAssist)
    }
}
