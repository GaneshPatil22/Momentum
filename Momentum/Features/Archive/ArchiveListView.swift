//
//  ArchiveListView.swift
//  Momentum
//
//  Finished initiatives that silently archived themselves (or were archived
//  by hand). Opening this screen clears the Archive notch. Adding a task to
//  any of these revives it (handled in ActivityService.addTask); Restore
//  brings it back without new work.
//

import SwiftUI
import SwiftData

struct ArchiveListView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(
        filter: #Predicate<Initiative> { $0.isArchived },
        sort: \Initiative.archivedAt, order: .reverse
    )
    private var archived: [Initiative]

    var body: some View {
        NavigationStack {
            Group {
                if archived.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Archive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .navigationDestination(for: Initiative.self) { initiative in
                InitiativeDetailView(initiative: initiative)
            }
        }
        // Visiting the Archive marks everything seen — the notch goes away.
        .task { ArchiveService.clearUnseen() }
    }

    private var list: some View {
        List {
            Section {
                ForEach(archived) { initiative in
                    NavigationLink(value: initiative) {
                        row(initiative)
                    }
                    .swipeActions(edge: .trailing) {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            delete(initiative)
                        }
                        Button("Restore", systemImage: "tray.and.arrow.up") {
                            restore(initiative)
                        }
                        .tint(AppColor.accent)
                    }
                }
            } footer: {
                Text("Finished initiatives archive themselves after \(ArchiveService.autoArchiveDays) quiet days. Add a task to bring one back.")
            }
        }
    }

    private func row(_ initiative: Initiative) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: initiative.colorHex) ?? AppColor.text3)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(initiative.name)
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(AppColor.text)
                    .lineLimit(1)
                Text(archivedCaption(initiative))
                    .font(.caption)
                    .foregroundStyle(AppColor.text2)
            }
        }
        .padding(.vertical, 2)
    }

    private func archivedCaption(_ initiative: Initiative) -> String {
        let count = initiative.tasks.count
        let tasksText = "^[\(count) task](inflect: true) done"
        if let archivedAt = initiative.archivedAt {
            return "\(tasksText) · archived \(archivedAt.formatted(.relative(presentation: .named)))"
        }
        return tasksText
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Archive is empty", systemImage: "archivebox")
        } description: {
            Text("Finished initiatives land here automatically once they've been quiet for \(ArchiveService.autoArchiveDays) days.")
        }
    }

    private func restore(_ initiative: Initiative) {
        initiative.isArchived = false
        initiative.archivedAt = nil
        try? context.save()
    }

    private func delete(_ initiative: Initiative) {
        context.delete(initiative)
        try? context.save()
    }
}

private extension Color {
    init?(hex: String) {
        var trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("#") { trimmed.removeFirst() }
        guard trimmed.count == 6, let value = UInt64(trimmed, radix: 16) else { return nil }
        let r = Double((value & 0xFF0000) >> 16) / 255.0
        let g = Double((value & 0x00FF00) >> 8) / 255.0
        let b = Double(value & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
