//
//  ArchiveService.swift
//  Momentum
//
//  Silent completion: a *finished* initiative (all tasks done) that goes
//  untouched for a while archives itself. There's no "complete" button —
//  archiving IS completion. Newly auto-archived initiatives raise a notch
//  on the Archive button so the user notices what quietly moved.
//

import Foundation
import SwiftData

@Observable
@MainActor
final class ArchiveService {
    /// Days of inactivity (on top of being fully done) before silent archiving.
    static let autoArchiveDays = 10

    /// UserDefaults key for the unseen-auto-archived notch count. Views read it via @AppStorage.
    static let unseenCountKey = "unseenArchivedCount"

    @ObservationIgnored private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    /// Auto-archive every finished, idle initiative. Bumps the unseen notch by however many moved.
    func sweep(now: Date = .now) {
        let descriptor = FetchDescriptor<Initiative>(
            predicate: #Predicate { !$0.isArchived }
        )
        guard let candidates = try? context.fetch(descriptor) else { return }

        var archivedCount = 0
        for initiative in candidates where initiative.shouldAutoArchive(now: now) {
            initiative.isArchived = true
            initiative.archivedAt = now
            archivedCount += 1
        }

        guard archivedCount > 0 else { return }
        try? context.save()

        let defaults = UserDefaults.standard
        let previous = defaults.integer(forKey: Self.unseenCountKey)
        defaults.set(previous + archivedCount, forKey: Self.unseenCountKey)
    }

    /// Clears the notch — called when the user opens the Archive screen.
    static func clearUnseen() {
        UserDefaults.standard.set(0, forKey: unseenCountKey)
    }
}

extension Initiative {
    /// True only when there's real work that's all been finished.
    func allTasksComplete() -> Bool {
        !tasks.isEmpty && tasks.allSatisfy(\.isDone)
    }

    /// A finished initiative that's gone quiet long enough to silently archive.
    func shouldAutoArchive(
        now: Date = .now,
        archiveDays: Int = ArchiveService.autoArchiveDays
    ) -> Bool {
        !isArchived
            && allTasksComplete()
            && daysSinceActivity(now: now) >= archiveDays
    }
}
