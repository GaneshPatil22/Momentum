//
//  SyncStatusService.swift
//  Momentum
//
//  Surfaces SwiftData ↔ CloudKit sync state for a status indicator.
//  SwiftData drives an NSPersistentCloudKitContainer under the hood; we
//  observe its event stream to report idle / syncing / error.
//

import Foundation
import CoreData
import SwiftData

@Observable
@MainActor
final class SyncStatusService {
    enum State: Equatable {
        /// CloudKit isn't active (no iCloud entitlement yet, or the container fell back to a local store).
        case localOnly
        /// CloudKit active, nothing in flight.
        case idle
        /// An import or export is in progress.
        case syncing
        /// The last sync event failed. Carries the user-facing message.
        case error(String)
    }

    private(set) var state: State

    @ObservationIgnored private var observer: NSObjectProtocol?

    init(cloudKitActive: Bool) {
        state = cloudKitActive ? .idle : .localOnly
        guard cloudKitActive else { return }

        observer = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard
                let event = note.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                    as? NSPersistentCloudKitContainer.Event
            else { return }
            let newState = Self.mapState(event)
            // queue: .main guarantees we're already on the main actor.
            MainActor.assumeIsolated {
                self?.state = newState
            }
        }
    }

    /// SPEC §9 error copy — friendly, reassuring, never alarming.
    nonisolated static let offlineMessage =
        "Can't reach iCloud. Your changes are saved on this device and will sync when you're back."

    nonisolated private static func mapState(_ event: NSPersistentCloudKitContainer.Event) -> State {
        if event.error != nil { return .error(offlineMessage) }
        return event.endDate == nil ? .syncing : .idle
    }

    // MARK: - Display helpers

    var systemImage: String {
        switch state {
        case .localOnly: "icloud.slash"
        case .idle: "checkmark.icloud"
        case .syncing: "arrow.triangle.2.circlepath.icloud"
        case .error: "exclamationmark.icloud"
        }
    }

    var accessibilityLabel: String {
        switch state {
        case .localOnly: "iCloud sync off — saved on this device"
        case .idle: "iCloud up to date"
        case .syncing: "Syncing with iCloud"
        case .error: "iCloud sync problem"
        }
    }

    /// Non-nil only when there's something worth showing the user in an alert.
    var alertMessage: String? {
        if case let .error(message) = state { return message }
        return nil
    }
}
