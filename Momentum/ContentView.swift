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
    @Environment(NotificationService.self) private var notifications
    @AppStorage(SettingsKey.appearance) private var appearance = AppearanceSetting.system.rawValue
    @AppStorage(SettingsKey.hasOnboarded) private var hasOnboarded = false

    @State private var showSplash = true
    @State private var didRequestNotifications = false

    var body: some View {
        @Bindable var router = router
        return ZStack {
            TabView(selection: $router.selectedTab) {
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

            // Onboarding sits above the app but below the splash, so the splash
            // always shows first, then reveals onboarding (or the app) beneath.
            if !hasOnboarded {
                OnboardingView()
                    .transition(.opacity)
                    .zIndex(1)
            }

            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: hasOnboarded)
        .preferredColorScheme(AppearanceSetting(rawValue: appearance)?.colorScheme)
        .task {
            try? await Task.sleep(for: .seconds(1.8))
            withAnimation(.easeOut(duration: 0.45)) { showSplash = false }
        }
        .onChange(of: showSplash) { _, _ in requestNotificationsIfReady() }
        .onChange(of: hasOnboarded) { _, _ in requestNotificationsIfReady() }
    }

    /// Ask for notification permission only once the user is actually in the app —
    /// after the splash, and after onboarding for first-time users.
    private func requestNotificationsIfReady() {
        guard !showSplash, hasOnboarded, !didRequestNotifications else { return }
        didRequestNotifications = true
        Task { await notifications.requestAuthorization() }
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
        .environment(NotificationService(context: container.mainContext))
}
