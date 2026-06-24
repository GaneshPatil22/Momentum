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

    @Relationship(deleteRule: .cascade, inverse: \TaskItem.initiative)
    var tasks: [TaskItem] = []

    #Index<Initiative>([\.lastActivityAt], [\.isArchived])

    init(name: String, colorHex: String) {
        self.name = name
        self.colorHex = colorHex
    }
}
