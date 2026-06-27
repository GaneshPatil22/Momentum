//
//  Initiative.swift
//  Momentum
//
//  Created by Ganesh Patil on 24/06/26.
//

import Foundation
import SwiftData

@Model
final class Initiative {
    // Property-level defaults are required for CloudKit sync; real values flow through init.
    var id: UUID = UUID()
    var name: String = ""
    var colorHex: String = "#4F8EF7"
    var createdAt: Date = Date()
    var lastActivityAt: Date = Date()
    var isArchived: Bool = false
    /// When the initiative was archived (auto or manual); nil while live. Drives the archive list sort.
    var archivedAt: Date? = nil
    /// True once we've sent the "gone cold" nudge for the current cold episode. Reset on any activity.
    var coldNotified: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \TaskItem.initiative)
    var tasks: [TaskItem] = []

    #Index<Initiative>([\.lastActivityAt], [\.isArchived])

    init(name: String, colorHex: String) {
        self.name = name
        self.colorHex = colorHex
    }
}
