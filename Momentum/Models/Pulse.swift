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
}

extension Initiative {
    func daysSinceActivity(now: Date = .now) -> Int {
        Calendar.current.dateComponents([.day], from: lastActivityAt, to: now).day ?? 0
    }

    func pulse(now: Date = .now, thresholds: PulseThresholds = .default) -> Pulse {
        let days = daysSinceActivity(now: now)
        if days >= thresholds.coldAt { return .cold }
        if days >= thresholds.coolingAt { return .cooling }
        return .active
    }
}
