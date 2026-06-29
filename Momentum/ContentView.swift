//
//  ContentView.swift
//  Momentum
//
//  Created by Ganesh Patil on 24/06/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppRouter.self) private var router
    @AppStorage(SettingsKey.appearance) private var appearance = AppearanceSetting.system.rawValue
    @AppStorage(SettingsKey.hasOnboarded) private var hasOnboarded = false

    var body: some View {
        @Bindable var router = router
        return TabView(selection: $router.selectedTab) {
            Tab("Today", systemImage: "sun.max", value: AppRouter.Tab.today) {
                TodayView()
            }
            Tab("Initiatives", systemImage: "list.bullet.rectangle", value: AppRouter.Tab.initiatives) {
                InitiativesListView()
            }
            Tab("Momentum", systemImage: "chart.line.uptrend.xyaxis", value: AppRouter.Tab.momentum) {
                MomentumDashboardView()
            }
        }
        .tint(AppColor.accent)
        .preferredColorScheme(AppearanceSetting(rawValue: appearance)?.colorScheme)
        .fullScreenCover(isPresented: .init(get: { !hasOnboarded }, set: { hasOnboarded = !$0 })) {
            OnboardingView()
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Initiative.self, TaskItem.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return ContentView()
        .modelContainer(container)
        .environment(ActivityService(context: container.mainContext))
        .environment(SyncStatusService(cloudKitActive: false))
        .environment(AppRouter(context: container.mainContext))
}
