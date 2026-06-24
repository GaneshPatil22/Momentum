//
//  InitiativeRow.swift
//  Momentum
//
//  Created by Ganesh Patil on 24/06/26.
//

import SwiftUI

struct InitiativeRow: View {
    let initiative: Initiative

    var body: some View {
        let pulse = initiative.pulse()
        let days = initiative.daysSinceActivity()

        HStack(spacing: 13) {
            PulseDot(pulse: pulse)

            VStack(alignment: .leading, spacing: 2) {
                Text(initiative.name)
                    .font(.system(size: 16, weight: .semibold))
                Text("^[\(openTaskCount) open](inflect: true)")
                    .font(.system(size: 12.5))
                    .foregroundStyle(AppColor.text2)
            }

            Spacer()

            DaysSinceLabel(days: days, pulse: pulse)
        }
        .padding(.vertical, 2)
        .listRowBackground(rowBackground(for: pulse))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(initiative.name), \(pulse.displayName), \(daysAccessibility(days))")
    }

    private var openTaskCount: Int {
        initiative.tasks.filter { !$0.isDone }.count
    }

    @ViewBuilder
    private func rowBackground(for pulse: Pulse) -> some View {
        if pulse == .cold {
            LinearGradient(
                colors: [PulseColor.coldRowTint, .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            Color.clear
        }
    }

    private func daysAccessibility(_ days: Int) -> String {
        switch days {
        case 0: "today"
        case 1: "1 day since activity"
        default: "\(days) days since activity"
        }
    }
}
