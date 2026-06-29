//
//  AIAssistSheet.swift
//  Momentum
//
//  Streams AI suggestions in, lets the user pick which to keep, and commits
//  only the selected ones via ActivityService. The model never writes.
//

import SwiftUI
import FoundationModels

struct AIAssistSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AIAssistService.self) private var ai
    @Environment(ActivityService.self) private var activityService

    let mode: AssistMode
    let candidates: [Initiative]

    @State private var items: [AssistItem] = []
    @State private var selected: Set<Int> = []
    @State private var phase: Phase = .generating
    @State private var errorMessage: String?

    private enum Phase { case generating, done, error, unavailable }

    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .unavailable: unavailableView
                case .error: errorView
                case .generating, .done: suggestionList
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(addButtonTitle) { addSelected() }
                        .fontWeight(.semibold)
                        .disabled(phase != .done || selectedAddableCount == 0)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .task { await generate() }
    }

    // MARK: - Generation

    private func generate() async {
        guard ai.isAvailable else { phase = .unavailable; return }
        phase = .generating
        items = []
        selected = []

        do {
            let session = LanguageModelSession { ai.instructions(for: mode) }
            let stream = session.streamResponse(
                to: ai.prompt(for: mode, candidates: candidates),
                generating: SuggestionList.self
            )
            for try await partial in stream {
                items = mapped(partial.content)
            }
            // Pre-select everything we can actually act on.
            selected = Set(items.indices.filter { items[$0].initiative != nil })
            phase = .done
        } catch {
            errorMessage = error.localizedDescription
            phase = .error
        }
    }

    private func mapped(_ partial: SuggestionList.PartiallyGenerated) -> [AssistItem] {
        (partial.tasks ?? []).compactMap { suggestion in
            guard let rawTitle = suggestion.title else { return nil }
            let title = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else { return nil }
            let initiative = resolveInitiative(suggestion.initiative ?? "")
            return AssistItem(
                title: title,
                initiative: initiative,
                initiativeName: initiative?.name ?? (suggestion.initiative ?? "")
            )
        }
    }

    private func resolveInitiative(_ name: String) -> Initiative? {
        if case .breakDown(let target) = mode { return target }
        return ai.resolve(name, in: candidates)
    }

    // MARK: - Commit

    private func addSelected() {
        for index in selected.sorted() where items.indices.contains(index) {
            guard let initiative = items[index].initiative else { continue }
            activityService.addTask(items[index].title, to: initiative)
        }
        dismiss()
    }

    private var selectedAddableCount: Int {
        selected.filter { items.indices.contains($0) && items[$0].initiative != nil }.count
    }

    private var addButtonTitle: String {
        selectedAddableCount > 0 ? "Add \(selectedAddableCount)" : "Add"
    }

    // MARK: - Views

    private var showsInitiativeName: Bool {
        if case .breakDown = mode { return false }
        return true
    }

    private var suggestionList: some View {
        List {
            Section {
                ForEach(items.indices, id: \.self) { index in
                    row(index)
                }
                if phase == .generating {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text(items.isEmpty ? "Thinking…" : "More coming…")
                            .foregroundStyle(AppColor.text3)
                    }
                    .padding(.vertical, 4)
                }
            } footer: {
                if phase == .done {
                    Text("Suggestions only — nothing is saved until you add it.")
                }
            }
        }
    }

    @ViewBuilder
    private func row(_ index: Int) -> some View {
        let item = items[index]
        let addable = item.initiative != nil
        let isSelected = selected.contains(index)

        Button {
            guard phase == .done, addable else { return }
            if isSelected { selected.remove(index) } else { selected.insert(index) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? AppColor.accent : AppColor.text3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .foregroundStyle(AppColor.text)
                        .multilineTextAlignment(.leading)
                    if showsInitiativeName {
                        Text(addable ? item.initiativeName : "\(item.initiativeName) (not found)")
                            .font(.caption)
                            .foregroundStyle(AppColor.text2)
                    }
                }
                Spacer(minLength: 0)
            }
            .contentShape(.rect)
            .opacity(addable ? 1 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(phase != .done || !addable)
    }

    private var unavailableView: some View {
        ContentUnavailableView {
            Label("Assist unavailable", systemImage: "sparkles")
        } description: {
            Text(ai.unavailableMessage ?? "Assist isn't available right now.")
        }
    }

    private var errorView: some View {
        ContentUnavailableView {
            Label("Couldn't generate", systemImage: "exclamationmark.triangle")
        } description: {
            Text(errorMessage ?? "Something went wrong. Try again.")
        } actions: {
            Button("Try again") { Task { await generate() } }
                .buttonStyle(.borderedProminent)
        }
    }
}

struct AssistItem: Identifiable {
    let id = UUID()
    var title: String
    var initiative: Initiative?
    var initiativeName: String
}
