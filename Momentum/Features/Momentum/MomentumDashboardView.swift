//
//  MomentumDashboardView.swift
//  Momentum
//
//  Created by Ganesh Patil on 24/06/26.
//

import SwiftUI
import SwiftData
import Charts

struct MomentumDashboardView: View {
    @Query(
        filter: #Predicate<Initiative> { !$0.isArchived },
        sort: \Initiative.lastActivityAt, order: .forward
    )
    private var initiatives: [Initiative]

    @State private var window = 14
    @Namespace private var ringNamespace

    var body: some View {
        NavigationStack {
            Group {
                if initiatives.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            activityCard
                            if !goingCold.isEmpty { leaderboardCard }
                            ringGridCard
                        }
                        .padding(16)
                    }
                    .background(AppColor.bg)
                }
            }
            .navigationTitle("Momentum")
            .navigationDestination(for: Initiative.self) { initiative in
                InitiativeDetailView(initiative: initiative)
                    .navigationTransition(.zoom(sourceID: initiative.id, in: ringNamespace))
            }
        }
    }

    // MARK: - Derived data

    private var allTasks: [TaskItem] { initiatives.flatMap(\.tasks) }

    private var chartData: [ActivityPoint] {
        ActivityHistory.dailyCounts(for: allTasks, days: window)
    }

    private var totalMoves: Int { chartData.reduce(0) { $0 + $1.count } }

    /// Cooling + cold, stalest-first (the @Query is already ascending by lastActivityAt).
    private var goingCold: [Initiative] {
        initiatives.filter { $0.pulse() != .active }
    }

    // MARK: - Activity chart

    private var activityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                eyebrow("ACTIVITY")
                Spacer()
                Picker("Window", selection: $window) {
                    Text("14d").tag(14)
                    Text("30d").tag(30)
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }

            Text("^[\(totalMoves) move](inflect: true) in \(window) days")
                .font(.system(.title3, weight: .heavy))
                .foregroundStyle(AppColor.text)

            Chart(chartData) { point in
                BarMark(
                    x: .value("Day", point.date, unit: .day),
                    y: .value("Moves", point.count)
                )
                .foregroundStyle(AppColor.accent.gradient)
                .cornerRadius(3)
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3))
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: window == 14 ? 3 : 7)) { value in
                    AxisValueLabel(format: .dateTime.day().month(.narrow))
                }
            }
            .frame(height: 150)
        }
        .padding(16)
        .cardSurface()
    }

    // MARK: - Going-cold leaderboard

    private var leaderboardCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            eyebrow("GOING COLD")
            VStack(spacing: 0) {
                ForEach(Array(goingCold.prefix(5).enumerated()), id: \.element.id) { index, initiative in
                    NavigationLink(value: initiative) {
                        leaderboardRow(initiative)
                    }
                    .buttonStyle(.plain)
                    if index < min(goingCold.count, 5) - 1 {
                        Divider().overlay(AppColor.hairline)
                    }
                }
            }
        }
        .padding(16)
        .cardSurface()
    }

    private func leaderboardRow(_ initiative: Initiative) -> some View {
        let pulse = initiative.pulse()
        let days = initiative.daysSinceActivity()
        return HStack(spacing: 12) {
            PulseDot(pulse: pulse)
            Text(initiative.name)
                .font(.system(.body, weight: .semibold))
                .foregroundStyle(AppColor.text)
                .lineLimit(1)
            Spacer()
            DaysSinceLabel(days: days, pulse: pulse)
        }
        .padding(.vertical, 10)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(initiative.name), \(pulse.displayName), \(days) days since activity")
    }

    // MARK: - Ring grid

    private var ringGridCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            eyebrow("ALL INITIATIVES")
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)],
                spacing: 16
            ) {
                ForEach(initiatives) { initiative in
                    NavigationLink(value: initiative) {
                        ringCell(initiative)
                    }
                    .buttonStyle(.plain)
                    .matchedTransitionSource(id: initiative.id, in: ringNamespace)
                }
            }
        }
    }

    private func ringCell(_ initiative: Initiative) -> some View {
        let pulse = initiative.pulse()
        let days = initiative.daysSinceActivity()
        return VStack(spacing: 10) {
            PulseRing(pulse: pulse, days: days, showsDays: true)
            Text(initiative.name)
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(AppColor.text)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .cardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(initiative.name), \(pulse.displayName), \(days) days since activity")
    }

    // MARK: - Pieces

    private func eyebrow(_ text: String) -> some View {
        Text(text)
            .font(.system(.caption, weight: .semibold))
            .tracking(0.6)
            .foregroundStyle(AppColor.text3)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No momentum yet", systemImage: "chart.line.uptrend.xyaxis")
        } description: {
            Text("Add initiatives and check off tasks — your rings and activity chart show up here.")
        }
    }
}

private extension View {
    func cardSurface() -> some View {
        self
            .background(AppColor.surface)
            .clipShape(.rect(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppColor.hairline, lineWidth: 1)
            }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Initiative.self, TaskItem.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return MomentumDashboardView()
        .modelContainer(container)
        .environment(ActivityService(context: container.mainContext))
}
