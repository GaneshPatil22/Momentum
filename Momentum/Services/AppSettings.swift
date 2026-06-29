//
//  AppSettings.swift
//  Momentum
//
//  User-tunable preferences, persisted in UserDefaults. The pulse thresholds
//  and quiet hours that were hardcoded in earlier phases now read through here,
//  so the Settings screen can drive them.
//

import SwiftUI

enum SettingsKey {
    static let appearance = "appearance"
    static let pulseCoolingAt = "pulseCoolingAt"
    static let pulseColdAt = "pulseColdAt"
    static let quietStartHour = "quietStartHour"
    static let quietEndHour = "quietEndHour"
    static let notificationsEnabled = "notificationsEnabled"
    static let hasOnboarded = "hasOnboarded"
}

enum AppearanceSetting: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

extension UserDefaults {
    /// Reads an Int key, falling back to `fallback` when it was never set
    /// (distinguishing "unset" from a legitimate 0).
    func int(forKey key: String, default fallback: Int) -> Int {
        object(forKey: key) as? Int ?? fallback
    }

    func bool(forKey key: String, default fallback: Bool) -> Bool {
        object(forKey: key) as? Bool ?? fallback
    }
}
