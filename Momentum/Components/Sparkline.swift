//
//  Sparkline.swift
//  Momentum
//
//  A tiny Canvas bar chart of recent daily activity. Canvas (not Swift
//  Charts) keeps it cheap enough to render inside every list row.
//

import SwiftUI

struct Sparkline: View {
    let values: [Int]
    var color: Color = AppColor.accent

    var body: some View {
        Canvas { context, size in
            guard !values.isEmpty else { return }
            let maxValue = max(values.max() ?? 0, 1)
            let gap: CGFloat = 1.5
            let count = CGFloat(values.count)
            let barWidth = max((size.width - gap * (count - 1)) / count, 0.5)

            for (index, value) in values.enumerated() {
                let fraction = CGFloat(value) / CGFloat(maxValue)
                let barHeight = value > 0 ? max(size.height * fraction, 2) : 1.5
                let x = CGFloat(index) * (barWidth + gap)
                let rect = CGRect(
                    x: x,
                    y: size.height - barHeight,
                    width: barWidth,
                    height: barHeight
                )
                let fill: Color = value > 0 ? color : color.opacity(0.18)
                context.fill(
                    Path(roundedRect: rect, cornerRadius: barWidth / 2),
                    with: .color(fill)
                )
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview("Sparklines") {
    VStack(alignment: .leading, spacing: 20) {
        Sparkline(values: [0, 1, 0, 3, 2, 0, 0, 4, 1, 0, 2, 5, 1, 3])
            .frame(width: 80, height: 24)
        Sparkline(values: Array(repeating: 0, count: 14))
            .frame(width: 80, height: 24)
    }
    .padding(40)
}
