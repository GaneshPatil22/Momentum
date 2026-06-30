//
//  OnboardingView.swift
//  Momentum
//
//  Shown once on first launch: explains the pulse mechanic, then drops the
//  user into an empty Initiatives list ready to add their first thing.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage(SettingsKey.hasOnboarded) private var hasOnboarded = false
    @State private var page = 0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                pulsePage.tag(0)
                motionPage.tag(1)
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button(page == 1 ? "Get started" : "Continue") {
                if page == 1 {
                    hasOnboarded = true
                } else {
                    withAnimation { page = 1 }
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppColor.accent)
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 14))
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(AppColor.bg.ignoresSafeArea())
    }

    // MARK: - Pages

    private var pulsePage: some View {
        page(
            title: "Every initiative has a pulse",
            body: "Momentum tracks how recently you've moved each thing forward. Touch it and it's active. Leave it and it cools — then goes cold."
        ) {
            HStack(spacing: 28) {
                pulseSample(.active, "Active")
                pulseSample(.cooling, "Cooling")
                pulseSample(.cold, "Cold")
            }
            .padding(.vertical, 12)
        }
    }

    private var motionPage: some View {
        page(
            title: "Only forward motion counts",
            body: "Adding or completing a task revives an initiative's pulse. Finish everything and leave it quiet, and it quietly archives itself — no \"done\" button needed."
        ) {
            Image(systemName: "bolt.heart.fill")
                .font(.system(size: 64))
                .foregroundStyle(PulseColor.active)
                .padding(.vertical, 12)
        }
    }

    private func pulseSample(_ pulse: Pulse, _ label: String) -> some View {
        VStack(spacing: 10) {
            PulseDot(pulse: pulse, size: 22)
            Text(label)
                .font(.caption)
                .foregroundStyle(AppColor.text2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) pulse")
    }

    private func page<Art: View>(
        title: String,
        body: String,
        @ViewBuilder art: () -> Art
    ) -> some View {
        VStack(spacing: 24) {
            Spacer()
            art()
            VStack(spacing: 14) {
                Text(title)
                    .font(.system(.title, weight: .heavy))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppColor.text)
                Text(body)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppColor.text2)
            }
            .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
    }
}
