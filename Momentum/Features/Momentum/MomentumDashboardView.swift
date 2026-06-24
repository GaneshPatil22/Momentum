//
//  MomentumDashboardView.swift
//  Momentum
//
//  Created by Ganesh Patil on 24/06/26.
//

import SwiftUI

struct MomentumDashboardView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("Momentum", systemImage: "chart.line.uptrend.xyaxis")
            } description: {
                Text("Coming in P4 — animated pulse rings, the going-cold leaderboard, and your 14-day activity chart.")
            }
            .navigationTitle("Momentum")
        }
    }
}

#Preview {
    MomentumDashboardView()
}
