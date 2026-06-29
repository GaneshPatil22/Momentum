//
//  AIAssistService.swift
//  Momentum
//
//  On-device AI (Foundation Models), never autonomous. It only ever
//  *suggests* — the user explicitly accepts before anything is written.
//  Three jobs: break a goal down, focus for today, weekly review.
//

import Foundation
import FoundationModels

// MARK: - Parseable suggestion shapes

@Generable
struct SuggestionList {
    @Guide(description: "A short list of concrete next actions")
    var tasks: [Suggestion]
}

@Generable
struct Suggestion {
    @Guide(description: "The exact initiative name this action belongs to")
    var initiative: String

    @Guide(description: "A short, concrete next step, under 10 words, no trailing punctuation")
    var title: String
}

// MARK: - Modes

enum AssistMode: Identifiable {
    case breakDown(Initiative)
    case focusToday
    case weeklyReview

    var id: String {
        switch self {
        case .breakDown(let initiative): "break-\(initiative.id)"
        case .focusToday: "focus"
        case .weeklyReview: "weekly"
        }
    }

    var title: String {
        switch self {
        case .breakDown: "Break it down"
        case .focusToday: "Focus for today"
        case .weeklyReview: "Weekly review"
        }
    }
}

// MARK: - Service

@Observable
@MainActor
final class AIAssistService {
    private let model = SystemLanguageModel.default

    var isAvailable: Bool {
        if case .available = model.availability { return true }
        return false
    }

    /// User-facing reason the model can't be used, or nil when it's available.
    var unavailableMessage: String? {
        switch model.availability {
        case .available:
            return nil
        case .unavailable(.deviceNotEligible):
            return "This device doesn't support Apple Intelligence, so Assist is off."
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Turn on Apple Intelligence in Settings to use Assist."
        case .unavailable(.modelNotReady):
            return "The on-device model is still getting ready. Try again shortly."
        case .unavailable:
            return "Assist isn't available right now."
        @unknown default:
            return "Assist isn't available right now."
        }
    }

    // MARK: Prompt building

    func instructions(for mode: AssistMode) -> String {
        switch mode {
        case .breakDown:
            return """
            You are a focused productivity coach. Break the user's goal into a few small, \
            concrete, immediately-actionable next steps. Each step is a single task under 10 \
            words. No commentary, no numbering.
            """
        case .focusToday:
            return """
            You are a productivity coach helping the user keep neglected projects alive. \
            Suggest a few high-impact next actions aimed at the most neglected initiatives. \
            Each is a single small task. Use the exact initiative names provided.
            """
        case .weeklyReview:
            return """
            You are a productivity coach writing a brief weekly review. For each initiative \
            that has gone cold, suggest exactly one small, concrete revival step. Use the \
            exact initiative names provided.
            """
        }
    }

    func prompt(for mode: AssistMode, candidates: [Initiative]) -> String {
        switch mode {
        case .breakDown(let initiative):
            return """
            Goal: \(initiative.name).
            Suggest 3 to 6 small next actions that move this goal forward.
            Set the initiative field of every suggestion to exactly "\(initiative.name)".
            """
        case .focusToday:
            return """
            Here are my initiatives (name — days since activity — open tasks):
            \(initiativeLines(candidates))

            Suggest 1 to 3 high-impact next actions focused on the most neglected initiatives. \
            Use the exact initiative names above.
            """
        case .weeklyReview:
            return """
            Here are my initiatives (name — pulse — days since activity — open tasks):
            \(initiativeLines(candidates, includePulse: true))

            For each initiative that is cold, suggest one small revival action. \
            Use the exact initiative names above.
            """
        }
    }

    private func initiativeLines(_ candidates: [Initiative], includePulse: Bool = false) -> String {
        candidates.map { initiative in
            let days = initiative.daysSinceActivity()
            let open = initiative.tasks.filter { !$0.isDone }.map(\.title)
            let openText = open.isEmpty ? "none" : open.joined(separator: ", ")
            if includePulse {
                return "- \(initiative.name) — \(initiative.pulse().displayName) — \(days)d — open: \(openText)"
            }
            return "- \(initiative.name) — \(days)d — open: \(openText)"
        }
        .joined(separator: "\n")
    }

    // MARK: Resolution

    /// Match a model-returned initiative name back to a real object.
    func resolve(_ name: String, in candidates: [Initiative]) -> Initiative? {
        let target = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !target.isEmpty else { return nil }
        return candidates.first { $0.name.lowercased() == target }
    }
}
