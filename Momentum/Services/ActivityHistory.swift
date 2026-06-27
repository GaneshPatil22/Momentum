//
//  ActivityHistory.swift
//  Momentum
//
//  Derives a per-day forward-motion series from task timestamps.
//  There's no separate event log — every task carries its `createdAt`
//  and (if done) `completedAt`, and those *are* the forward-motion events
//  the pulse cares about. Pure + deterministic so it's trivial to test.
//

import Foundation

struct ActivityPoint: Identifiable, Equatable {
    let date: Date          // start-of-day bucket
    let count: Int
    var id: Date { date }
}

enum ActivityHistory {
    /// Every forward-motion event timestamp across the given tasks:
    /// a task being created, and a task being completed.
    static func eventDates(for tasks: [TaskItem]) -> [Date] {
        var dates: [Date] = []
        dates.reserveCapacity(tasks.count * 2)
        for task in tasks {
            dates.append(task.createdAt)
            if let completedAt = task.completedAt {
                dates.append(completedAt)
            }
        }
        return dates
    }

    /// Contiguous daily buckets for the last `days` days (oldest → today),
    /// zero-filled so charts/sparklines always have a full window.
    static func dailyCounts(
        for tasks: [TaskItem],
        days: Int,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [ActivityPoint] {
        precondition(days > 0, "days must be positive")
        let today = calendar.startOfDay(for: now)
        guard let earliest = calendar.date(byAdding: .day, value: -(days - 1), to: today) else {
            return []
        }

        var buckets: [Date: Int] = [:]
        for offset in 0..<days {
            if let day = calendar.date(byAdding: .day, value: -offset, to: today) {
                buckets[day] = 0
            }
        }

        for event in eventDates(for: tasks) {
            let day = calendar.startOfDay(for: event)
            if day >= earliest && day <= today {
                buckets[day, default: 0] += 1
            }
        }

        return buckets.keys.sorted().map { ActivityPoint(date: $0, count: buckets[$0] ?? 0) }
    }

    /// Convenience for the sparkline, which only needs the bar heights.
    static func counts(
        for tasks: [TaskItem],
        days: Int,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [Int] {
        dailyCounts(for: tasks, days: days, now: now, calendar: calendar).map(\.count)
    }
}
