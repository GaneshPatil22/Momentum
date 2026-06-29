//
//  NotificationService.swift
//  Momentum
//
//  Local nudges when an initiative goes cold. One notification per cold
//  episode (deduped via Initiative.coldNotified), delayed out of quiet
//  hours, and deep-linked back into the right detail screen on tap.
//

import Foundation
import SwiftData
import UserNotifications

@Observable
@MainActor
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    @ObservationIgnored private let context: ModelContext

    /// Set by the app: routes a tapped notification to the right initiative.
    @ObservationIgnored var onOpenInitiative: ((UUID) -> Void)?

    private let center = UNUserNotificationCenter.current()

    init(context: ModelContext) {
        self.context = context
        super.init()
        center.delegate = self
    }

    func requestAuthorization() async {
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    // MARK: - Cold sweep

    /// Schedule a nudge for every newly-cold, live, not-yet-notified initiative.
    func sweepColdNotifications(now: Date = .now, thresholds: PulseThresholds = .current) {
        // Respect the master notifications toggle in Settings.
        guard UserDefaults.standard.bool(forKey: SettingsKey.notificationsEnabled, default: true) else { return }

        let descriptor = FetchDescriptor<Initiative>(
            predicate: #Predicate { !$0.isArchived }
        )
        guard let initiatives = try? context.fetch(descriptor) else { return }

        var changed = false
        for initiative in initiatives
        where initiative.pulse(now: now, thresholds: thresholds) == .cold && !initiative.coldNotified {
            scheduleColdNudge(for: initiative, now: now)
            initiative.coldNotified = true
            changed = true
        }
        if changed { try? context.save() }
    }

    private func scheduleColdNudge(for initiative: Initiative, now: Date) {
        let days = initiative.daysSinceActivity(now: now)

        let content = UNMutableNotificationContent()
        content.title = "\(initiative.name) has gone quiet"
        content.body = "\(days) days. One small step brings it back."
        content.sound = .default
        content.userInfo = ["initiativeID": initiative.id.uuidString]

        let trigger: UNNotificationTrigger
        if let fireDate = QuietHours.current.deferIfNeeded(now), fireDate > now {
            let comps = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second], from: fireDate
            )
            trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        } else {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        }

        let request = UNNotificationRequest(
            identifier: "cold-\(initiative.id.uuidString)",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    // MARK: - Delegate (deep link)

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show the nudge even if the app is foregrounded.
        completionHandler([.banner, .sound])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let idString = response.notification.request.content.userInfo["initiativeID"] as? String
        if let idString, let id = UUID(uuidString: idString) {
            Task { @MainActor in self.onOpenInitiative?(id) }
        }
        completionHandler()
    }
}

/// A nightly do-not-disturb window. Hardcoded for now; user-tunable in Settings (P7).
struct QuietHours {
    var startHour: Int   // inclusive, 24h
    var endHour: Int     // exclusive, 24h

    static let standard = QuietHours(startHour: 22, endHour: 8)

    /// The user's configured window (Settings), falling back to `.standard`.
    static var current: QuietHours {
        let defaults = UserDefaults.standard
        return QuietHours(
            startHour: defaults.int(forKey: SettingsKey.quietStartHour, default: standard.startHour),
            endHour: defaults.int(forKey: SettingsKey.quietEndHour, default: standard.endHour)
        )
    }

    private var spansMidnight: Bool { startHour > endHour }

    func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        let hour = calendar.component(.hour, from: date)
        if spansMidnight {
            return hour >= startHour || hour < endHour
        }
        return hour >= startHour && hour < endHour
    }

    /// If `date` lands in quiet hours, returns the next end-of-quiet-hours; otherwise nil (fire now).
    func deferIfNeeded(_ date: Date, calendar: Calendar = .current) -> Date? {
        guard contains(date, calendar: calendar) else { return nil }
        let hour = calendar.component(.hour, from: date)
        // If we're past midnight but still before endHour, the window ends later today.
        let endIsTomorrow = spansMidnight && hour >= startHour
        let base = endIsTomorrow ? calendar.date(byAdding: .day, value: 1, to: date) ?? date : date
        return calendar.date(
            bySettingHour: endHour, minute: 0, second: 0, of: base
        )
    }
}
