//
//  DaysSinceLabel.swift
//  Momentum
//
//  Created by Ganesh Patil on 24/06/26.
//

import SwiftUI

struct DaysSinceLabel: View {
    let days: Int
    let pulse: Pulse?

    init(days: Int, pulse: Pulse? = nil) {
        self.days = days
        self.pulse = pulse
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text("\(days)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(numberColor)
            Text(subscriptText)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .tracking(0.7)
                .foregroundStyle(AppColor.text3)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var numberColor: Color {
        if let pulse {
            return pulse.color
        }
        return AppColor.text2
    }

    private var subscriptText: String {
        switch days {
        case 0: "TODAY"
        case 1: "DAY"
        default: "DAYS"
        }
    }

    private var accessibilityText: String {
        switch days {
        case 0: "Today"
        case 1: "1 day"
        default: "\(days) days"
        }
    }
}

#Preview("Days labels") {
    HStack(spacing: 30) {
        DaysSinceLabel(days: 0, pulse: .active)
        DaysSinceLabel(days: 1, pulse: .active)
        DaysSinceLabel(days: 5, pulse: .cooling)
        DaysSinceLabel(days: 11, pulse: .cold)
    }
    .padding(40)
}
