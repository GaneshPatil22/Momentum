//
//  AppRouter.swift
//  Momentum
//
//  App-level navigation state. Owns the selected tab and the selected
//  initiative (shared with the Initiatives split view) so a notification
//  tap — or any other deep link — can route into the right detail screen.
//

import Foundation
import SwiftData

@Observable
@MainActor
final class AppRouter {
    enum Tab: Hashable {
        case today, initiatives, momentum
    }

    var selectedTab: Tab = .today
    var selectedInitiative: Initiative?

    @ObservationIgnored private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    /// Jump to the Initiatives tab and open this initiative's detail.
    func open(_ initiative: Initiative) {
        selectedTab = .initiatives
        selectedInitiative = initiative
    }

    /// Deep link: jump to the Initiatives tab and open the given initiative's detail.
    func openInitiative(id: UUID) {
        let descriptor = FetchDescriptor<Initiative>(
            predicate: #Predicate { $0.id == id }
        )
        guard let initiative = try? context.fetch(descriptor).first else { return }
        selectedTab = .initiatives
        selectedInitiative = initiative
    }
}
