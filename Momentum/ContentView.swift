//
//  ContentView.swift
//  Momentum
//
//  Created by Ganesh Patil on 24/06/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Today", systemImage: "sun.max") {
                TodayView()
            }
            Tab("Initiatives", systemImage: "list.bullet.rectangle") {
                InitiativesListView()
            }
            Tab("Momentum", systemImage: "chart.line.uptrend.xyaxis") {
                MomentumDashboardView()
            }
        }
        .tint(AppColor.accent)
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
}
