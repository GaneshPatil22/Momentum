//
//  InitiativeDetailView.swift
//  Momentum
//
//  Created by Ganesh Patil on 24/06/26.
//

import SwiftUI
import SwiftData

struct InitiativeDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(ActivityService.self) private var activityService

    let initiative: Initiative

    @State private var newTaskTitle: String = ""
    @FocusState private var newTaskFocused: Bool

    var body: some View {
        let pulse = initiative.pulse()
        let days = initiative.daysSinceActivity()

        List {
            Section {
                header(pulse: pulse, days: days)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
            }

            Section {
                AddBar(
                    placeholder: "Add task…",
                    text: $newTaskTitle,
                    isFocused: $newTaskFocused,
                    onSubmit: addTask
                )
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 12, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            if openTasks.isEmpty {
                Section {
                    Text("No open tasks. What's the next small step?")
                        .foregroundStyle(AppColor.text3)
                        .font(.callout)
                }
            } else {
                Section {
                    ForEach(openTasks) { task in
                        TaskItemRow(task: task)
                    }
                    .onDelete { offsets in deleteTasks(openTasks, at: offsets) }
                } header: {
                    sectionHeader("Open")
                }
            }

            if !doneTasks.isEmpty {
                Section {
                    ForEach(doneTasks) { task in
                        TaskItemRow(task: task)
                    }
                    .onDelete { offsets in deleteTasks(doneTasks, at: offsets) }
                } header: {
                    sectionHeader("Done")
                }
            }
        }
        .navigationTitle(initiative.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func header(pulse: Pulse, days: Int) -> some View {
        HStack(spacing: 16) {
            PulseRing(pulse: pulse, days: days)

            VStack(alignment: .leading, spacing: 4) {
                Text(initiative.name)
                    .font(.system(.title2, weight: .heavy))
                    .foregroundStyle(AppColor.text)
                Text(headerStatus(pulse: pulse, days: days))
                    .font(.system(.footnote, design: .rounded, weight: .bold))
                    .foregroundStyle(pulse.color)
            }
            Spacer()
        }
        .padding(18)
        .background(AppColor.surface)
        .clipShape(.rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColor.hairline, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(initiative.name), \(pulse.displayName), \(days) days since activity")
    }

    private func headerStatus(pulse: Pulse, days: Int) -> String {
        let day = days == 1 ? "day" : "days"
        return "\(pulse.displayName.capitalized) · \(days) \(day) since activity"
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(.caption, weight: .semibold))
            .tracking(0.6)
            .textCase(.uppercase)
            .foregroundStyle(AppColor.text3)
    }

    private var openTasks: [TaskItem] {
        initiative.tasks
            .filter { !$0.isDone }
            .sorted { $0.createdAt < $1.createdAt }
    }

    private var doneTasks: [TaskItem] {
        initiative.tasks
            .filter { $0.isDone }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    private func addTask() {
        let trimmed = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        activityService.addTask(trimmed, to: initiative)
        newTaskTitle = ""
        newTaskFocused = true
    }

    private func deleteTasks(_ source: [TaskItem], at offsets: IndexSet) {
        for index in offsets {
            context.delete(source[index])
        }
        try? context.save()
    }
}

private struct TaskItemRow: View {
    @Environment(ActivityService.self) private var activityService

    let task: TaskItem

    var body: some View {
        Button {
            activityService.toggleDone(task)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .strokeBorder(task.isDone ? PulseColor.active : AppColor.text3, lineWidth: 2)
                        .frame(width: 21, height: 21)
                    if task.isDone {
                        Circle()
                            .fill(PulseColor.active)
                            .frame(width: 21, height: 21)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppColor.bg)
                    }
                }
                .contentTransition(.symbolEffect(.replace))

                Text(task.title)
                    .strikethrough(task.isDone)
                    .foregroundStyle(task.isDone ? AppColor.text3 : AppColor.text)
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(task.title)
        .accessibilityValue(task.isDone ? "Completed" : "Open")
        .accessibilityAddTraits(.isButton)
    }
}
