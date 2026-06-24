//
//  ActivityService.swift
//  Momentum
//
//  Created by Ganesh Patil on 24/06/26.
//

import Foundation
import SwiftData

@Observable
final class ActivityService {
    @ObservationIgnored private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func registerActivity(for initiative: Initiative) {
        initiative.lastActivityAt = .now
    }

    @discardableResult
    func addTask(_ title: String, to initiative: Initiative) -> TaskItem {
        let task = TaskItem(title: title, initiative: initiative)
        context.insert(task)
        registerActivity(for: initiative)
        persist()
        return task
    }

    func toggleDone(_ task: TaskItem) {
        task.isDone.toggle()
        task.completedAt = task.isDone ? .now : nil
        if task.isDone, let initiative = task.initiative {
            registerActivity(for: initiative)
        }
        persist()
    }

    private func persist() {
        do {
            try context.save()
        } catch {
            print("[ActivityService] Save failed: \(error)")
        }
    }
}
