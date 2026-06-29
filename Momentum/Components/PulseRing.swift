//
//  PulseRing.swift
//  Momentum
//
//  Created by Ganesh Patil on 24/06/26.
//

import SwiftUI

struct PulseRing: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let pulse: Pulse
    let days: Int
    let thresholds: PulseThresholds
    let showsDays: Bool
    @ScaledMetric private var scaledSize: CGFloat

    @State private var breathing = false

    init(
        pulse: Pulse,
        days: Int,
        thresholds: PulseThresholds = .current,
        size: CGFloat = 62,
        showsDays: Bool = false
    ) {
        self.pulse = pulse
        self.days = days
        self.thresholds = thresholds
        self.showsDays = showsDays
        _scaledSize = ScaledMetric(wrappedValue: size)
    }

    /// Cold initiatives are drained — they don't breathe. Reduce Motion stills everything.
    private var animates: Bool { pulse != .cold && !reduceMotion }

    var body: some View {
        ZStack {
            if animates {
                Circle()
                    .stroke(pulse.color, lineWidth: 6)
                    .scaleEffect(breathing ? 1.12 : 1.0)
                    .opacity(breathing ? 0.0 : 0.45)
                    .blur(radius: 1)
            }

            Circle()
                .stroke(AppColor.surface3, lineWidth: 6)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(pulse.color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))

            if showsDays {
                VStack(spacing: 0) {
                    Text("\(days)")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(pulse.color)
                    Text(daysUnit)
                        .font(.system(size: 8, weight: .semibold, design: .rounded))
                        .tracking(0.6)
                        .foregroundStyle(AppColor.text3)
                }
            }
        }
        .frame(width: scaledSize, height: scaledSize)
        .onAppear(perform: syncBreathing)
        .onChange(of: animates) { _, _ in syncBreathing() }
        .accessibilityHidden(true)
    }

    private var daysUnit: String {
        switch days {
        case 0: "TODAY"
        case 1: "DAY"
        default: "DAYS"
        }
    }

    private func syncBreathing() {
        guard animates else {
            breathing = false
            return
        }
        let duration = pulse == .active ? 1.3 : 2.0
        withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
            breathing = true
        }
    }

    private var progress: Double {
        let cap = max(thresholds.coldAt, 1)
        return min(Double(days) / Double(cap), 1.0)
    }
}

#Preview("Pulse rings") {
    HStack(spacing: 24) {
        PulseRing(pulse: .active, days: 1, showsDays: true)
        PulseRing(pulse: .cooling, days: 5, showsDays: true)
        PulseRing(pulse: .cold, days: 11, showsDays: true)
    }
    .padding(40)
}
