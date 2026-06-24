//
//  NewInitiativeSheet.swift
//  Momentum
//
//  Created by Ganesh Patil on 24/06/26.
//

import SwiftUI
import SwiftData

struct NewInitiativeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var name: String = ""
    @State private var selectedColor: String = ColorPalette.presets[0]
    @FocusState private var nameFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Learn Korean", text: $name)
                        .focused($nameFocused)
                        .submitLabel(.done)
                        .onSubmit(commit)
                }
                Section("Color") {
                    colorGrid
                }
            }
            .navigationTitle("New initiative")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add", action: commit)
                        .disabled(trimmedName.isEmpty)
                        .fontWeight(.semibold)
                }
            }
            .onAppear { nameFocused = true }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var colorGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
            ForEach(ColorPalette.presets, id: \.self) { hex in
                Button {
                    selectedColor = hex
                } label: {
                    Circle()
                        .fill(Color(hex: hex) ?? .gray)
                        .frame(width: 32, height: 32)
                        .overlay {
                            Circle()
                                .strokeBorder(.primary, lineWidth: selectedColor == hex ? 2 : 0)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(ColorPalette.name(for: hex))
                .accessibilityAddTraits(selectedColor == hex ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }

    private func commit() {
        guard !trimmedName.isEmpty else { return }
        let initiative = Initiative(name: trimmedName, colorHex: selectedColor)
        context.insert(initiative)
        try? context.save()
        dismiss()
    }
}

private enum ColorPalette {
    static let presets: [String] = [
        "#5B8DEF",
        "#2FD4A7",
        "#F6B23C",
        "#FF6B6B",
        "#A77BF0",
        "#4FB6E0",
    ]

    static func name(for hex: String) -> String {
        switch hex {
        case "#5B8DEF": "Blue"
        case "#2FD4A7": "Teal"
        case "#F6B23C": "Amber"
        case "#FF6B6B": "Coral"
        case "#A77BF0": "Purple"
        case "#4FB6E0": "Sky"
        default: "Custom"
        }
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
