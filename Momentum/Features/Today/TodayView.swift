//
//  TodayView.swift
//  Momentum
//
//  Created by Ganesh Patil on 24/06/26.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(AppRouter.self) private var router
    @Environment(ActivityService.self) private var activityService

    @Query(
        filter: #Predicate<Initiative> { !$0.isArchived },
        sort: \Initiative.lastActivityAt, order: .forward
    )
    private var initiatives: [Initiative]

    @State private var quickAddText = ""
    @FocusState private var quickAddFocused: Bool

    var body: some View {
        NavigationStack {
            Group {
                if initiatives.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            if let cold = coldInitiatives.first {
                                attentionBanner(cold: cold, total: coldInitiatives.count)
                            }
                            suggestedFocus
                            if let stalest = initiatives.first {
                                quickAdd(to: stalest)
                            }
                        }
                        .padding(16)
                    }
                    .background(AppColor.bg)
                }
            }
            .navigationTitle("Today")
        }
    }

    // MARK: - Derived

    private var coldInitiatives: [Initiative] {
        initiatives.filter { $0.pulse() == .cold }
    }

    /// Stalest-first: each initiative's oldest open task. Up to three.
    private var suggestions: [(initiative: Initiative, task: TaskItem)] {
        initiatives.compactMap { initiative in
            guard let task = initiative.tasks
                .filter({ !$0.isDone })
                .min(by: { $0.createdAt < $1.createdAt })
            else { return nil }
            return (initiative, task)
        }
        .prefix(3)
        .map { $0 }
    }

    // MARK: - Attention banner

    private func attentionBanner(cold: Initiative, total: Int) -> some View {
        let days = cold.daysSinceActivity()
        return Button {
            router.open(cold)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(PulseColor.cooling)
                VStack(alignment: .leading, spacing: 3) {
                    Text(bannerTitle(cold: cold, total: total))
                        .font(.system(.subheadline, weight: .bold))
                        .foregroundStyle(AppColor.text)
                        .multilineTextAlignment(.leading)
                    Text("\(days) days quiet. One small step brings it back.")
                        .font(.caption)
                        .foregroundStyle(AppColor.text2)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColor.text3)
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [PulseColor.coolingHalo, AppColor.surface],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .clipShape(.rect(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppColor.hairline, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func bannerTitle(cold: Initiative, total: Int) -> String {
        if total <= 1 {
            return "\(cold.name) has gone quiet"
        }
        return "\(cold.name) and \(total - 1) more have gone quiet"
    }

    // MARK: - Suggested focus

    @ViewBuilder
    private var suggestedFocus: some View {
        if suggestions.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                eyebrow("SUGGESTED FOCUS")
                Text("Nothing open right now. Add a small next step below.")
                    .font(.callout)
                    .foregroundStyle(AppColor.text3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .cardSurface()
            }
        } else {
            VStack(alignment: .leading, spacing: 10) {
                eyebrow("SUGGESTED FOCUS")
                VStack(spacing: 0) {
                    ForEach(Array(suggestions.enumerated()), id: \.element.task.id) { index, pair in
                        focusRow(initiative: pair.initiative, task: pair.task)
                        if index < suggestions.count - 1 {
                            Divider().overlay(AppColor.hairline)
                        }
                    }
                }
                .cardSurface()
            }
        }
    }

    private func focusRow(initiative: Initiative, task: TaskItem) -> some View {
        HStack(spacing: 12) {
            Button {
                activityService.toggleDone(task)
            } label: {
                Circle()
                    .strokeBorder(AppColor.text3, lineWidth: 2)
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Complete \(task.title)")

            Button {
                router.open(initiative)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.system(.body, weight: .medium))
                        .foregroundStyle(AppColor.text)
                        .lineLimit(1)
                    Text(initiative.name)
                        .font(.caption)
                        .foregroundStyle(AppColor.text2)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)

            PulseDot(pulse: initiative.pulse())
        }
        .padding(14)
    }

    // MARK: - Quick add

    private func quickAdd(to initiative: Initiative) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            eyebrow("QUICK ADD")
            AddBar(
                placeholder: "Add a task to \(initiative.name)…",
                text: $quickAddText,
                isFocused: $quickAddFocused,
                onSubmit: { commitQuickAdd(to: initiative) }
            )
        }
    }

    private func commitQuickAdd(to initiative: Initiative) {
        let trimmed = quickAddText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        activityService.addTask(trimmed, to: initiative)
        quickAddText = ""
        quickAddFocused = true
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
            Label("All clear", systemImage: "sun.max.fill")
        } description: {
            Text("Add an initiative to start tracking what you're keeping alive.")
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
