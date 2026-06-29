//
//  Pulse.swift
//  Momentum
//
//  Created by Ganesh Patil on 24/06/26.
//

import Foundation

enum Pulse: String, Codable, CaseIterable, Sendable {
    case active, cooling, cold
}

struct PulseThresholds: Codable, Sendable, Equatable {
    var coolingAt: Int
    var coldAt: Int

    static let `default` = PulseThresholds(coolingAt: 3, coldAt: 7)

    /// The user's current thresholds (Settings), falling back to `.default`.
    static var current: PulseThresholds {
        let defaults = UserDefaults.standard
        return PulseThresholds(
            coolingAt: defaults.int(forKey: SettingsKey.pulseCoolingAt, default: `default`.coolingAt),
            coldAt: defaults.int(forKey: SettingsKey.pulseColdAt, default: `default`.coldAt)
        )
    }
}

extension Initiative {
    func daysSinceActivity(now: Date = .now) -> Int {
        Calendar.current.dateComponents([.day], from: lastActivityAt, to: now).day ?? 0
    }

    func pulse(now: Date = .now, thresholds: PulseThresholds = .current) -> Pulse {
        let days = daysSinceActivity(now: now)
        if days >= thresholds.coldAt { return .cold }
        if days >= thresholds.coolingAt { return .cooling }
        return .active
    }
}
