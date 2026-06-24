//
//  PulseRing.swift
//  Momentum
//
//  Created by Ganesh Patil on 24/06/26.
//

import SwiftUI

struct PulseRing: View {
    let pulse: Pulse
    let days: Int
    let thresholds: PulseThresholds
    @ScaledMetric private var scaledSize: CGFloat

    init(pulse: Pulse, days: Int, thresholds: PulseThresholds = .default, size: CGFloat = 62) {
        self.pulse = pulse
        self.days = days
        self.thresholds = thresholds
        _scaledSize = ScaledMetric(wrappedValue: size)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColor.surface3, lineWidth: 6)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(pulse.color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: scaledSize, height: scaledSize)
        .accessibilityHidden(true)
    }

    private var progress: Double {
        let cap = max(thresholds.coldAt, 1)
        return min(Double(days) / Double(cap), 1.0)
    }
}

#Preview("Pulse rings") {
    HStack(spacing: 24) {
        PulseRing(pulse: .active, days: 1)
        PulseRing(pulse: .cooling, days: 5)
        PulseRing(pulse: .cold, days: 11)
    }
    .padding(40)
}
