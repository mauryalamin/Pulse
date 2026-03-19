//
//  InsightsContentRefreshCoordinator.swift
//  Pulse
//
//  Created by Codex on 3/16/26.
//

import Foundation

protocol InsightsContentRefreshing {
    func resolveWeeklySummary(
        templateSummary: InsightsSummary?,
        input: InsightsWeeklySummaryInput?,
        dataState: InsightsDataState,
        asOf date: Date
    ) async -> InsightsSummary?

    func resolveObservations(
        templateObservations: [InsightObservation],
        input: InsightsObservationsGenerationInput?,
        dataState: InsightsDataState,
        asOf date: Date
    ) async -> [InsightObservation]
}

final class InsightsContentRefreshCoordinator: InsightsContentRefreshing {
    private let weeklySummaryGenerator: InsightsWeeklySummaryGenerating
    private let observationsGenerator: InsightsObservationsGenerating
    private let defaults: UserDefaults

    private let storageKey = "pulse.insights.contentRefreshState"
    private let freshnessWindow: TimeInterval = 24 * 60 * 60
    private let maxEntriesPerType = 12

    private var state: PersistedState

    init(
        weeklySummaryGenerator: InsightsWeeklySummaryGenerating = InsightsWeeklySummaryGenerationService(),
        observationsGenerator: InsightsObservationsGenerating = InsightsObservationsGenerationService(),
        defaults: UserDefaults = .standard
    ) {
        self.weeklySummaryGenerator = weeklySummaryGenerator
        self.observationsGenerator = observationsGenerator
        self.defaults = defaults
        self.state = PersistedState()
        self.state = loadState()
    }

    func resolveWeeklySummary(
        templateSummary: InsightsSummary?,
        input: InsightsWeeklySummaryInput?,
        dataState: InsightsDataState,
        asOf date: Date
    ) async -> InsightsSummary? {
        guard dataState == .ready, let input else {
            return templateSummary
        }

        let fingerprint = input.signature
        let cached = state.weeklySummaryByFingerprint[fingerprint]

        if let cached, isFresh(cached.cachedAt, asOf: date) {
            return cached.summary
        }

        do {
            let generated = try await weeklySummaryGenerator.generateWeeklySummary(from: input, generatedAt: date)
            saveWeeklySummary(generated, for: fingerprint, cachedAt: date)
            return generated
        } catch {
            // If refresh fails, prefer existing AI text for this fingerprint when available.
            if let cached, cached.summary.source == .foundationModel {
                return cached.summary
            }

            // Then reuse any same-fingerprint cached value, otherwise fallback template.
            if let cached {
                return cached.summary
            }

            return templateSummary
        }
    }

    func resolveObservations(
        templateObservations: [InsightObservation],
        input: InsightsObservationsGenerationInput?,
        dataState: InsightsDataState,
        asOf date: Date
    ) async -> [InsightObservation] {
        guard dataState == .ready, let input else {
            return templateObservations
        }

        let fingerprint = input.signature
        let cached = state.observationsByFingerprint[fingerprint]

        if let cached, isFresh(cached.cachedAt, asOf: date) {
            return cached.observations
        }

        do {
            let generated = try await observationsGenerator.generateObservations(from: input, generatedAt: date)

            guard !generated.isEmpty else {
                if let cached {
                    return cached.observations
                }
                return templateObservations
            }

            saveObservations(generated, for: fingerprint, cachedAt: date)
            return generated
        } catch {
            // If refresh fails, prefer existing AI observations for this fingerprint when available.
            if let cached,
               cached.observations.contains(where: { $0.source == .foundationModel }) {
                return cached.observations
            }

            // Then reuse any same-fingerprint cached value, otherwise fallback template.
            if let cached {
                return cached.observations
            }

            return templateObservations
        }
    }
}

private extension InsightsContentRefreshCoordinator {
    func isFresh(_ cachedAt: Date, asOf date: Date) -> Bool {
        date.timeIntervalSince(cachedAt) < freshnessWindow
    }

    func saveWeeklySummary(_ summary: InsightsSummary, for fingerprint: String, cachedAt: Date) {
        state.weeklySummaryByFingerprint[fingerprint] = CachedWeeklySummary(
            fingerprint: fingerprint,
            summary: summary,
            cachedAt: cachedAt
        )

        if state.weeklySummaryByFingerprint.count > maxEntriesPerType {
            let oldest = state.weeklySummaryByFingerprint
                .sorted { $0.value.cachedAt < $1.value.cachedAt }
                .prefix(state.weeklySummaryByFingerprint.count - maxEntriesPerType)
                .map(\.key)

            oldest.forEach { state.weeklySummaryByFingerprint.removeValue(forKey: $0) }
        }

        saveState()
    }

    func saveObservations(_ observations: [InsightObservation], for fingerprint: String, cachedAt: Date) {
        state.observationsByFingerprint[fingerprint] = CachedObservations(
            fingerprint: fingerprint,
            observations: observations,
            cachedAt: cachedAt
        )

        if state.observationsByFingerprint.count > maxEntriesPerType {
            let oldest = state.observationsByFingerprint
                .sorted { $0.value.cachedAt < $1.value.cachedAt }
                .prefix(state.observationsByFingerprint.count - maxEntriesPerType)
                .map(\.key)

            oldest.forEach { state.observationsByFingerprint.removeValue(forKey: $0) }
        }

        saveState()
    }

    func loadState() -> PersistedState {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(PersistedState.self, from: data) else {
            return PersistedState()
        }
        return decoded
    }

    func saveState() {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: storageKey)
    }
}

private struct PersistedState: Codable, Sendable {
    var weeklySummaryByFingerprint: [String: CachedWeeklySummary] = [:]
    var observationsByFingerprint: [String: CachedObservations] = [:]
}

private struct CachedWeeklySummary: Codable, Sendable {
    let fingerprint: String
    let summary: InsightsSummary
    let cachedAt: Date
}

private struct CachedObservations: Codable, Sendable {
    let fingerprint: String
    let observations: [InsightObservation]
    let cachedAt: Date
}
