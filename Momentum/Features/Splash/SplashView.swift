//
//  SplashView.swift
//  Momentum
//
//  A SwiftUI splash that continues seamlessly from the launch storyboard
//  (same dark background + ring) and lingers briefly with a drawing-in ring,
//  so the launch doesn't just flash past.
//

import SwiftUI

struct SplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var progress: CGFloat = 0
    @State private var nameVisible = false

    var body: some View {
        ZStack {
            AppColor.bg.ignoresSafeArea()

            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .stroke(AppColor.surface3, lineWidth: 9)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: [PulseColor.active, AppColor.accent],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 9, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 84, height: 84)

                Text("Momentum")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(AppColor.text)
                    .opacity(nameVisible ? 1 : 0)
            }
        }
        .onAppear {
            if reduceMotion {
                progress = 0.82
                nameVisible = true
            } else {
                withAnimation(.easeInOut(duration: 1.1)) { progress = 0.82 }
                withAnimation(.easeIn(duration: 0.6).delay(0.35)) { nameVisible = true }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Momentum")
    }
}
