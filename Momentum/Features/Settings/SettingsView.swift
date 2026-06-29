//
//  SettingsView.swift
//  Momentum
//
//  The real home for appearance, pulse thresholds, notification + quiet-hours
//  preferences, iCloud sync status, and archived initiatives.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(SyncStatusService.self) private var syncStatus

    @AppStorage(SettingsKey.appearance) private var appearance = AppearanceSetting.system.rawValue
    @AppStorage(SettingsKey.pulseCoolingAt) private var coolingAt = PulseThresholds.default.coolingAt
    @AppStorage(SettingsKey.pulseColdAt) private var coldAt = PulseThresholds.default.coldAt
    @AppStorage(SettingsKey.notificationsEnabled) private var notificationsEnabled = true
    @AppStorage(SettingsKey.quietStartHour) private var quietStartHour = QuietHours.standard.startHour
    @AppStorage(SettingsKey.quietEndHour) private var quietEndHour = QuietHours.standard.endHour

    @State private var showingArchive = false

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                pulseSection
                notificationsSection
                iCloudSection
                archiveSection
                aboutSection
                #if DEBUG
                developerSection
                #endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingArchive) {
                ArchiveListView()
            }
        }
        // A sheet has its own presentation context, so re-apply the appearance here
        // for the theme to switch live while Settings is open.
        .preferredColorScheme(AppearanceSetting(rawValue: appearance)?.colorScheme)
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: $appearance) {
                ForEach(AppearanceSetting.allCases) { option in
                    Text(option.label).tag(option.rawValue)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var pulseSection: some View {
        Section {
            Stepper(value: $coolingAt, in: 1...(coldAt - 1)) {
                LabeledContent("Cooling after") {
                    Text("^[\(coolingAt) day](inflect: true)")
                }
            }
            Stepper(value: $coldAt, in: (coolingAt + 1)...60) {
                LabeledContent("Cold after") {
                    Text("^[\(coldAt) day](inflect: true)")
                }
            }
        } header: {
            Text("Pulse")
        } footer: {
            Text("How long without activity before an initiative cools, then goes cold.")
        }
    }

    private var notificationsSection: some View {
        Section {
            Toggle("Cold nudges", isOn: $notificationsEnabled)
            if notificationsEnabled {
                Picker("Quiet from", selection: $quietStartHour) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text(hourLabel(hour)).tag(hour)
                    }
                }
                Picker("Quiet until", selection: $quietEndHour) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text(hourLabel(hour)).tag(hour)
                    }
                }
            }
        } header: {
            Text("Notifications")
        } footer: {
            Text("Nudges that would land during quiet hours are held until the window ends.")
        }
    }

    private var iCloudSection: some View {
        Section("iCloud") {
            HStack(spacing: 12) {
                Image(systemName: syncStatus.systemImage)
                    .foregroundStyle(AppColor.text2)
                Text(syncStatus.accessibilityLabel)
                    .foregroundStyle(AppColor.text)
            }
        }
    }

    private var archiveSection: some View {
        Section {
            Button {
                showingArchive = true
            } label: {
                LabeledContent("Archived initiatives") {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColor.text3)
                }
            }
            .tint(AppColor.text)
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: appVersion)
            LabeledContent("App", value: "Momentum")
        }
    }

    #if DEBUG
    private var developerSection: some View {
        Section("Developer") {
            Button("Load sample data") {
                SampleData.seed(into: modelContext)
                dismiss()
            }
        }
    }
    #endif

    private func hourLabel(_ hour: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        guard let date = Calendar.current.date(from: components) else { return "\(hour):00" }
        return date.formatted(.dateTime.hour())
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }
}
