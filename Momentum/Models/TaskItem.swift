//
//  TaskItem.swift
//  Momentum
//
//  Created by Ganesh Patil on 24/06/26.
//

import Foundation
import SwiftData

@Model
final class TaskItem {
    var id: UUID = UUID()
    var title: String = ""
    var isDone: Bool = false
    var createdAt: Date = Date()
    var completedAt: Date?

    var initiative: Initiative?

    #Index<TaskItem>([\.isDone])

    init(title: String, initiative: Initiative? = nil) {
        self.title = title
        self.initiative = initiative
    }
}
