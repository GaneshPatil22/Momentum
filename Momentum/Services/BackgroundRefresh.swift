//
//  BackgroundRefresh.swift
//  Momentum
//
//  Once-a-day background sweep: auto-archive finished initiatives and fire
//  cold nudges even when the app hasn't been opened. Requires Background
//  Modes + a BGTaskSchedulerPermittedIdentifiers entry in Info.plist — until
//  that's added it self-disables, and the foreground sweep covers the gap.
//

import Foundation
import BackgroundTasks

enum BackgroundRefresh {
    static let identifier = "testing.Momentum.refresh"

    private static var work: (() -> Void)?

    /// Only active once the identifier is declared in Info.plist; otherwise registering
    /// or submitting would throw, so we no-op.
    static var isEnabled: Bool {
        guard let ids = Bundle.main.object(
            forInfoDictionaryKey: "BGTaskSchedulerPermittedIdentifiers"
        ) as? [String] else { return false }
        return ids.contains(identifier)
    }

    /// Register the handler. Must run before the app finishes launching (call from App.init).
    static func register(_ work: @escaping () -> Void) {
        guard isEnabled else { return }
        self.work = work
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: .main) { task in
            MainActor.assumeIsolated { handle(task) }
        }
    }

    /// Ask the system to run us again in roughly half a day.
    static func schedule() {
        guard isEnabled else { return }
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 12 * 60 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    private static func handle(_ task: BGTask) {
        task.expirationHandler = {}
        schedule()              // chain the next run
        work?()                 // sweeps are fast + synchronous
        task.setTaskCompleted(success: true)
    }
}
