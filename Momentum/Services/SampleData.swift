//
//  SampleData.swift
//  Momentum
//
//  Curated test data covering every pulse state plus the archive flow.
//  Triggered from Settings (DEBUG) or by launching with `-seedSampleData`.
//

import Foundation
import SwiftData

enum SampleData {
    /// Wipes existing data and inserts a varied set of initiatives + tasks.
    static func seed(into context: ModelContext) {
        // Clear everything first so the set is deterministic.
        try? context.delete(model: TaskItem.self)
        try? context.delete(model: Initiative.self)

        let now = Date.now
        let calendar = Calendar.current
        func day(_ n: Int) -> Date { calendar.date(byAdding: .day, value: -n, to: now) ?? now }

        func make(
            _ name: String,
            _ colorHex: String,
            daysAgo: Int,
            open: [String] = [],
            done: [String] = [],
            archivedDaysAgo: Int? = nil
        ) {
            let initiative = Initiative(name: name, colorHex: colorHex)
            initiative.lastActivityAt = day(daysAgo)
            context.insert(initiative)

            // Open tasks, created over the days leading up to the last activity.
            for (index, title) in open.enumerated() {
                let task = TaskItem(title: title, initiative: initiative)
                task.createdAt = day(daysAgo + index + 1)
                context.insert(task)
            }
            // Done tasks, completed around the last-activity date.
            for (index, title) in done.enumerated() {
                let task = TaskItem(title: title, initiative: initiative)
                task.createdAt = day(daysAgo + open.count + index + 2)
                task.isDone = true
                task.completedAt = day(daysAgo)
                context.insert(task)
            }

            if let archivedDaysAgo {
                initiative.isArchived = true
                initiative.archivedAt = day(archivedDaysAgo)
            }
        }

        // Active (0–2 days)
        make("Ship Momentum v1", "#5B8DEF", daysAgo: 0,
             open: ["Fix settings theme bug", "Add app icon", "Write App Store copy"],
             done: ["Build settings screen"])
        make("Learn Korean", "#2FD4A7", daysAgo: 1,
             open: ["Memorize Hangul", "Practice greetings"])
        make("Marathon training", "#F6B23C", daysAgo: 2,
             open: ["Long run Saturday"],
             done: ["Buy running shoes", "10k tempo run"])

        // Cooling (3–6 days)
        make("Write the novel", "#FF6B6B", daysAgo: 4,
             open: ["Outline chapter 3"],
             done: ["Draft chapter 2"])
        make("Home gym setup", "#A77BF0", daysAgo: 5,
             open: ["Mount the rack", "Order rubber flooring"])

        // Cold (7+ days)
        make("Budget app side project", "#4FB6E0", daysAgo: 8,
             open: ["Sketch the data model", "Pick a chart library"],
             done: ["Register the domain"])
        make("Read 12 books", "#5B8DEF", daysAgo: 13,
             open: ["Start book #4"],
             done: ["Finish book #3", "Finish book #2"])
        make("Garden redesign", "#2FD4A7", daysAgo: 22,
             open: ["Call the landscaper"])

        // Archived (finished, then quiet) — surfaces the archive + notch flow
        make("Redesign portfolio", "#A77BF0", daysAgo: 14,
             done: ["Pick a template", "Write the bio", "Deploy the site"],
             archivedDaysAgo: 2)
        make("Spanish A1 course", "#F6B23C", daysAgo: 16,
             done: ["Finish unit 5", "Pass the final quiz"],
             archivedDaysAgo: 4)

        try? context.save()

        // Show the archive notch for the two freshly-archived initiatives.
        UserDefaults.standard.set(2, forKey: ArchiveService.unseenCountKey)
    }
}
