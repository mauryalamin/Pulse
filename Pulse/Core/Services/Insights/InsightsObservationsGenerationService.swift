//
//  InsightsObservationsGenerationService.swift
//  Pulse
//
//  Created by Codex on 3/16/26.
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

protocol InsightsObservationsGenerating {
    func generateObservations(
        from input: InsightsObservationsGenerationInput,
        generatedAt: Date
    ) async throws -> [InsightObservation]
}

struct InsightsObservationCandidate: Hashable, Sendable {
    let title: String?
    let body: String
    let signalKinds: [ObservationSignalKind]
    let priority: Int
}

struct InsightsObservationsGenerationInput: Hashable, Sendable {
    let periodLabel: String
    let summaryBody: String?
    let candidates: [InsightsObservationCandidate]

    var signature: String {
        let candidateSignature = candidates
            .sorted { $0.priority < $1.priority }
            .map {
                [
                    $0.title ?? "nil",
                    $0.body,
                    $0.signalKinds.map(\.rawValue).joined(separator: ","),
                    String($0.priority)
                ].joined(separator: "|")
            }
            .joined(separator: "||")

        return [periodLabel, summaryBody ?? "nil", candidateSignature].joined(separator: "###")
    }

    var instructions: String {
        """
        You write up to two short observations for a journaling insights view.
        Keep each line calm, neutral, and factual.
        Use only the candidate facts provided.
        Do not provide advice, diagnosis, coaching, causation claims, praise, or blame.
        Avoid repeating the weekly summary.
        Avoid generating two observations that say the same thing.
        If there is not enough distinct value, return NONE.
        """
    }

    var prompt: String {
        var lines: [String] = [
            "Period: \(periodLabel)",
            "Weekly summary: \(summaryBody ?? "Unavailable")",
            "Candidate observations:"
        ]

        for (index, candidate) in candidates.enumerated() {
            let signals = candidate.signalKinds.map(\.rawValue).joined(separator: ", ")
            lines.append("\(index + 1). [signals: \(signals)] \(candidate.body)")
        }

        lines.append("Output format: return NONE or one/two lines exactly formatted as 'OBS: <sentence>'.")
        return lines.joined(separator: "\n")
    }
}

enum InsightsObservationsGenerationError: Error {
    case modelUnavailable
}

struct InsightsObservationsGenerationService: InsightsObservationsGenerating {
    func generateObservations(
        from input: InsightsObservationsGenerationInput,
        generatedAt: Date
    ) async throws -> [InsightObservation] {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let model = SystemLanguageModel.default
            guard case .available = model.availability else {
                throw InsightsObservationsGenerationError.modelUnavailable
            }

            let session = LanguageModelSession(model: model, instructions: input.instructions)
            let response = try await session.respond(to: input.prompt)
            let raw = sanitize(response.content)
            let lines = parseObservationLines(from: raw)

            if lines.isEmpty {
                return []
            }

            let mapped = mapToObservations(lines, from: input.candidates, generatedAt: generatedAt)
            return suppress(mapped, against: input.summaryBody)
        }
        #endif

        throw InsightsObservationsGenerationError.modelUnavailable
    }
}

private extension InsightsObservationsGenerationService {
    func sanitize(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\"", with: "")
    }

    func parseObservationLines(from raw: String) -> [String] {
        if raw.uppercased().contains("NONE") {
            return []
        }

        return raw
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.lowercased().hasPrefix("obs:") }
            .map { String($0.dropFirst(4)).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(2)
            .map { $0 }
    }

    func mapToObservations(
        _ lines: [String],
        from candidates: [InsightsObservationCandidate],
        generatedAt: Date
    ) -> [InsightObservation] {
        lines.compactMap { line in
            guard let matched = bestMatchingCandidate(for: line, in: candidates) else {
                return nil
            }

            return InsightObservation(
                title: matched.title,
                body: line,
                source: .foundationModel,
                signalKinds: matched.signalKinds,
                priority: matched.priority,
                generatedAt: generatedAt
            )
        }
    }

    func bestMatchingCandidate(
        for line: String,
        in candidates: [InsightsObservationCandidate]
    ) -> InsightsObservationCandidate? {
        let scored = candidates.map { candidate in
            (candidate, similarityScore(line, candidate.body))
        }
        .sorted { $0.1 > $1.1 }

        guard let best = scored.first, best.1 >= 0.2 else {
            return nil
        }
        return best.0
    }

    func suppress(_ observations: [InsightObservation], against summaryBody: String?) -> [InsightObservation] {
        var output: [InsightObservation] = []

        for observation in observations.sorted(by: { $0.priority < $1.priority }) {
            if let summaryBody, similarityScore(observation.body, summaryBody) >= 0.65 {
                continue
            }

            let duplicatesExisting = output.contains { existing in
                similarityScore(existing.body, observation.body) >= 0.75
            }

            if duplicatesExisting {
                continue
            }

            output.append(observation)
            if output.count == 2 {
                break
            }
        }

        return output
    }

    func similarityScore(_ lhs: String, _ rhs: String) -> Double {
        let a = Set(tokens(from: lhs))
        let b = Set(tokens(from: rhs))

        guard !a.isEmpty, !b.isEmpty else { return 0 }
        let intersection = a.intersection(b).count
        let union = a.union(b).count

        guard union > 0 else { return 0 }
        return Double(intersection) / Double(union)
    }

    func tokens(from text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 2 }
    }
}
