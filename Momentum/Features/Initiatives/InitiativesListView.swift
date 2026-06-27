//
//  InitiativesListView.swift
//  Momentum
//
//  Created by Ganesh Patil on 24/06/26.
//

import SwiftUI
import SwiftData

struct InitiativesListView: View {
    @Environment(\.modelContext) private var context
    @Environment(SyncStatusService.self) private var syncStatus
    @Environment(AppRouter.self) private var router

    @Query(
        filter: #Predicate<Initiative> { !$0.isArchived },
        sort: \Initiative.lastActivityAt, order: .forward
    )
    private var initiatives: [Initiative]

    @State private var showingNewSheet = false
    @State private var editingInitiative: Initiative?
    @State private var showingSyncAlert = false
    @State private var showingArchive = false
    @AppStorage(ArchiveService.unseenCountKey) private var unseenArchivedCount = 0

    var body: some View {
        @Bindable var router = router
        return NavigationSplitView {
            Group {
                if initiatives.isEmpty {
                    emptyState
                } else {
                    listContent
                }
            }
            .navigationTitle("Initiatives")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    syncIndicator
                }
                ToolbarItem(placement: .topBarTrailing) {
                    archiveButton
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("New initiative", systemImage: "plus") {
                        showingNewSheet = true
                    }
                }
            }
            .sheet(isPresented: $showingArchive) {
                ArchiveListView()
            }
            .sheet(isPresented: $showingNewSheet) {
                NewInitiativeSheet()
            }
            .sheet(item: $editingInitiative) { initiative in
                NewInitiativeSheet(editing: initiative)
            }
            .alert("iCloud", isPresented: $showingSyncAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(syncStatus.alertMessage ?? "")
            }
        } detail: {
            if let selected = router.selectedInitiative {
                NavigationStack {
                    InitiativeDetailView(initiative: selected)
                }
            } else {
                noSelection
            }
        }
    }

    private var archiveButton: some View {
        Button {
            showingArchive = true
        } label: {
            Image(systemName: "archivebox")
                .overlay(alignment: .topTrailing) {
                    if unseenArchivedCount > 0 {
                        Text("\(unseenArchivedCount)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(Circle().fill(Color.red))
                            .offset(x: 9, y: -9)
                    }
                }
        }
        .accessibilityLabel(unseenArchivedCount > 0 ? "Archive, \(unseenArchivedCount) new" : "Archive")
    }

    @ViewBuilder
    private var syncIndicator: some View {
        Button {
            if syncStatus.alertMessage != nil { showingSyncAlert = true }
        } label: {
            if syncStatus.state == .syncing {
                ProgressView()
            } else {
                Image(systemName: syncStatus.systemImage)
                    .foregroundStyle(syncStatus.alertMessage != nil ? Color.red : AppColor.text3)
            }
        }
        .disabled(syncStatus.alertMessage == nil)
        .accessibilityLabel(syncStatus.accessibilityLabel)
    }

    private var listContent: some View {
        @Bindable var router = router
        return List(selection: $router.selectedInitiative) {
            ForEach(initiatives) { initiative in
                InitiativeRow(initiative: initiative)
                    .tag(initiative)
                    .contextMenu {
                        rowMenu(for: initiative)
                    }
            }
            .onDelete(perform: delete)
        }
    }

    @ViewBuilder
    private func rowMenu(for initiative: Initiative) -> some View {
        Button("Rename", systemImage: "pencil") {
            editingInitiative = initiative
        }
        Button("Change color", systemImage: "paintpalette") {
            editingInitiative = initiative
        }
        Divider()
        Button("Archive", systemImage: "archivebox") {
            archive(initiative)
        }
        Button("Delete", systemImage: "trash", role: .destructive) {
            deleteOne(initiative)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Nothing yet", systemImage: "circle.dotted")
        } description: {
            Text("Add the first thing you're trying to keep alive.")
        } actions: {
            Button("Add initiative") {
                showingNewSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var noSelection: some View {
        ContentUnavailableView(
            "Select an initiative",
            systemImage: "sidebar.left",
            description: Text("Pick something from the list to see its tasks.")
        )
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let initiative = initiatives[index]
            if router.selectedInitiative == initiative { router.selectedInitiative = nil }
            context.delete(initiative)
        }
        try? context.save()
    }

    private func deleteOne(_ initiative: Initiative) {
        if router.selectedInitiative == initiative { router.selectedInitiative = nil }
        context.delete(initiative)
        try? context.save()
    }

    private func archive(_ initiative: Initiative) {
        // Manual archive — deliberate, so it doesn't bump the auto-archive notch.
        // Not forward motion either, so lastActivityAt is left untouched.
        initiative.isArchived = true
        initiative.archivedAt = .now
        if router.selectedInitiative == initiative { router.selectedInitiative = nil }
        try? context.save()
    }
}
