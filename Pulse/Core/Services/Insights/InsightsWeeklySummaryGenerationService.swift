//
//  InsightsWeeklySummaryGenerationService.swift
//  Pulse
//
//  Created by Codex on 3/15/26.
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

protocol InsightsWeeklySummaryGenerating {
    func generateWeeklySummary(from input: InsightsWeeklySummaryInput, generatedAt: Date) async throws -> InsightsSummary
}

struct InsightsWeeklySummaryInput: Hashable, Sendable {
    let periodLabel: String
    let momentsLogged: String
    let stayedPresentRate: String
    let dominantTimeWindow: String?
    let mostCommonUrge: String?
    let topTag: String?
    let changeVsPreviousPeriod: String?

    /// Used to avoid regenerating when underlying deterministic inputs are unchanged.
    var signature: String {
        [
            periodLabel,
            momentsLogged,
            stayedPresentRate,
            dominantTimeWindow ?? "nil",
            mostCommonUrge ?? "nil",
            topTag ?? "nil",
            changeVsPreviousPeriod ?? "nil"
        ].joined(separator: "|")
    }

    var instructions: String {
        """
        You write one concise weekly journaling insight sentence.
        Keep it calm, observational, and neutral.
        Use only the provided facts.
        No advice, no diagnosis, no coaching, no causation claims.
        Keep to 12-26 words.
        """
    }

    var prompt: String {
        var lines: [String] = [
            "Period: \(periodLabel)",
            "Moments logged: \(momentsLogged)",
            "Stayed Present rate: \(stayedPresentRate)"
        ]

        if let dominantTimeWindow {
            lines.append("Most common time window: \(dominantTimeWindow)")
        }

        if let mostCommonUrge {
            lines.append("Most common urge: \(mostCommonUrge)")
        }

        if let topTag {
            lines.append("Top tag: \(topTag)")
        }

        if let changeVsPreviousPeriod {
            lines.append("Change vs previous period: \(changeVsPreviousPeriod)")
        }

        lines.append("Return one sentence only.")
        return lines.joined(separator: "\n")
    }
}

enum InsightsWeeklySummaryGenerationError: Error {
    case modelUnavailable
    case emptyResponse
}

struct InsightsWeeklySummaryGenerationService: InsightsWeeklySummaryGenerating {
    func generateWeeklySummary(from input: InsightsWeeklySummaryInput, generatedAt: Date) async throws -> InsightsSummary {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let model = SystemLanguageModel.default
            guard case .available = model.availability else {
                throw InsightsWeeklySummaryGenerationError.modelUnavailable
            }

            let session = LanguageModelSession(model: model, instructions: input.instructions)
            let response = try await session.respond(to: input.prompt)
            let body = sanitize(response.content)

            guard !body.isEmpty else {
                throw InsightsWeeklySummaryGenerationError.emptyResponse
            }

            return InsightsSummary(
                title: "\(input.periodLabel) Summary",
                body: body,
                source: .foundationModel,
                generatedAt: generatedAt
            )
        }
        #endif

        throw InsightsWeeklySummaryGenerationError.modelUnavailable
    }

    private func sanitize(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\"", with: "")
    }
}
