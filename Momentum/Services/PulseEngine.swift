//
//  PulseEngine.swift
//  Momentum
//
//  Created by Ganesh Patil on 24/06/26.
//

import Foundation

enum PulseEngine {
    static func sortedStalestFirst(_ initiatives: [Initiative]) -> [Initiative] {
        initiatives.sorted { $0.lastActivityAt < $1.lastActivityAt }
    }

    static func coldInitiatives(
        _ initiatives: [Initiative],
        now: Date = .now,
        thresholds: PulseThresholds = .current
    ) -> [Initiative] {
        initiatives.filter { $0.pulse(now: now, thresholds: thresholds) == .cold }
    }
}
