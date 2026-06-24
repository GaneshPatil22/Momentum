//
//  PulseDot.swift
//  Momentum
//
//  Created by Ganesh Patil on 24/06/26.
//

import SwiftUI

struct PulseDot: View {
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    let pulse: Pulse
    @ScaledMetric private var scaledSize: CGFloat

    init(pulse: Pulse, size: CGFloat = 12) {
        self.pulse = pulse
        _scaledSize = ScaledMetric(wrappedValue: size)
    }

    var body: some View {
        Group {
            if differentiateWithoutColor {
                Image(systemName: pulse.symbolName)
                    .foregroundStyle(pulse.color)
            } else {
                Circle()
                    .fill(pulse.color)
                    .frame(width: scaledSize, height: scaledSize)
                    .background {
                        Circle()
                            .fill(pulse.haloColor)
                            .frame(width: scaledSize + 8, height: scaledSize + 8)
                    }
            }
        }
        .accessibilityHidden(true)
    }
}

extension Pulse {
    var color: Color {
        switch self {
        case .active: PulseColor.active
        case .cooling: PulseColor.cooling
        case .cold: PulseColor.cold
        }
    }

    var haloColor: Color {
        switch self {
        case .active: PulseColor.activeHalo
        case .cooling: PulseColor.coolingHalo
        case .cold: .clear
        }
    }

    var symbolName: String {
        switch self {
        case .active: "circle.fill"
        case .cooling: "circle.lefthalf.filled"
        case .cold: "circle"
        }
    }

    var displayName: String {
        switch self {
        case .active: "active"
        case .cooling: "cooling"
        case .cold: "cold"
        }
    }
}

#Preview("Pulse dots") {
    HStack(spacing: 28) {
        PulseDot(pulse: .active)
        PulseDot(pulse: .cooling)
        PulseDot(pulse: .cold)
        PulseDot(pulse: .cold, size: 24)
    }
    .padding(40)
}
