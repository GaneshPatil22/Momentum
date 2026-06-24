//
//  TodayView.swift
//  Momentum
//
//  Created by Ganesh Patil on 24/06/26.
//

import SwiftUI

struct TodayView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("Today", systemImage: "sun.max.fill")
            } description: {
                Text("Coming in P5 — triage your most-neglected work in a single screen, with a heuristic suggestion of what to move next.")
            }
            .navigationTitle("Today")
        }
    }
}

#Preview {
    TodayView()
}
