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

    @Query(
        filter: #Predicate<Initiative> { !$0.isArchived },
        sort: \Initiative.lastActivityAt, order: .forward
    )
    private var initiatives: [Initiative]

    @State private var showingNewSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if initiatives.isEmpty {
                    emptyState
                } else {
                    listContent
                }
            }
            .navigationTitle("Initiatives")
            .navigationDestination(for: Initiative.self) { initiative in
                InitiativeDetailView(initiative: initiative)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("New initiative", systemImage: "plus") {
                        showingNewSheet = true
                    }
                }
            }
            .sheet(isPresented: $showingNewSheet) {
                NewInitiativeSheet()
            }
        }
    }

    private var listContent: some View {
        List {
            ForEach(initiatives) { initiative in
                NavigationLink(value: initiative) {
                    InitiativeRow(initiative: initiative)
                }
            }
            .onDelete(perform: delete)
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

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(initiatives[index])
        }
        try? context.save()
    }
}
