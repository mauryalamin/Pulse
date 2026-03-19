//
//  MomentsListViewModel.swift
//  Pulse
//
//  Created by Maury Alamin on 10/17/25.
//

import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class MomentsListViewModel {

    // MARK: - Filters (client-side friendly)
    var searchText: String = ""
    var selectedUrgeIDs: Set<PersistentIdentifier> = []
    var minIntensity: Int = 1
    var maxIntensity: Int = 5
    var stayedPresentOnly: Bool = false

    // MARK: - Render source
    var moments: [Moment] = []
    var insightsSnapshot: InsightsSnapshot

    // MARK: - Infra
    @ObservationIgnored private let context: ModelContext
    @ObservationIgnored private let insightsService: InsightsComputing
    @ObservationIgnored private let contentRefreshCoordinator: InsightsContentRefreshing
    @ObservationIgnored private let factoidSelector: InsightsFactoidSelecting

    init(
        context: ModelContext,
        insightsService: InsightsComputing = InsightsComputationService(),
        contentRefreshCoordinator: InsightsContentRefreshing = InsightsContentRefreshCoordinator(),
        factoidSelector: InsightsFactoidSelecting = InsightsFactoidSelectionService()
    ) {
        self.context = context
        self.insightsService = insightsService
        self.contentRefreshCoordinator = contentRefreshCoordinator
        self.factoidSelector = factoidSelector
        self.insightsSnapshot = Self.makeInitialSnapshot()
    }

    // Keep DB predicate SIMPLE (numeric/bool only) to avoid #Predicate complexity
    private var basePredicate: Predicate<Moment> {
        let minI = minIntensity
        let maxI = maxIntensity
        let stayedOnly = stayedPresentOnly
        return #Predicate<Moment> { m in
            m.intensity >= minI && m.intensity <= maxI
            && (!stayedOnly || m.gaveIn == false)
        }
    }

    /// Fetch from SwiftData, then apply richer filters client-side.
    func reload() async {
        do {
            let desc = FetchDescriptor<Moment>(
                predicate: basePredicate,
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            let serverResults = try context.fetch(desc)
            let filtered = applyClientFilters(to: serverResults)
            self.moments = filtered
            let now = Date.now
            let deterministicSnapshot = makeInsightsSnapshot(from: filtered, now: now)
            let summaryEnhancedSnapshot = await withResolvedWeeklySummary(
                from: deterministicSnapshot,
                generatedAt: now
            )
            let observationsEnhancedSnapshot = await withResolvedObservations(
                from: summaryEnhancedSnapshot,
                generatedAt: now
            )
            self.insightsSnapshot = withSelectedFactoids(
                from: observationsEnhancedSnapshot,
                generatedAt: now
            )
            // Debug (optional)
            // print("📥 Reloaded \(moments.count) moments (server: \(serverResults.count))")
        } catch {
            print("⚠️ Moments reload failed: \(error)")
        }
    }

    private func applyClientFilters(to input: [Moment]) -> [Moment] {
        let ids = selectedUrgeIDs
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        return input.filter { m in
            // Optional urge filter
            (ids.isEmpty || ids.contains(m.urge.id))
            // Search in note or urge name (localized)
            && (q.isEmpty
                || (m.note?.localizedStandardContains(q) ?? false)
                || m.urge.name.localizedStandardContains(q))
        }
    }

    // MARK: - Filter helpers (auto-reload)
    func setSearch(_ text: String) async {
        self.searchText = text
        await reload()
    }

    func setIntensity(min: Int, max: Int) async {
        self.minIntensity = min
        self.maxIntensity = max
        await reload()
    }

    func toggleStayedPresentOnly(_ flag: Bool) async {
        self.stayedPresentOnly = flag
        await reload()
    }

    func setSelectedUrges(_ ids: Set<PersistentIdentifier>) async {
        self.selectedUrgeIDs = ids
        await reload()
    }
}

private extension MomentsListViewModel {
    func makeInsightsSnapshot(from moments: [Moment], now: Date) -> InsightsSnapshot {
        let period = Self.defaultInsightsPeriod(referenceDate: now)
        return insightsService.makeSnapshot(from: moments, for: period, now: now)
    }

    static func defaultInsightsPeriod(referenceDate: Date) -> InsightsPeriod {
        let calendar = Calendar.current
        let endDate = referenceDate
        let startDay = calendar.startOfDay(for: endDate)
        let startDate = calendar.date(byAdding: .month, value: -6, to: startDay) ?? startDay

        return InsightsPeriod(
            label: "Last 6 Months",
            startDate: startDate,
            endDate: endDate,
            kind: .custom
        )
    }

    static func makeInitialSnapshot() -> InsightsSnapshot {
        let now = Date.now
        let period = defaultInsightsPeriod(referenceDate: now)

        return InsightsSnapshot(
            period: period,
            summary: nil,
            factoids: [],
            activitySeries: [],
            timePattern: nil,
            observations: [],
            topTags: [],
            urgeBreakdown: [],
            dataState: .empty,
            lastRefreshedAt: now
        )
    }

    func withResolvedWeeklySummary(
        from snapshot: InsightsSnapshot,
        generatedAt: Date
    ) async -> InsightsSnapshot {
        let templateSummary = snapshot.summary
        let input = snapshot.dataState == .ready ? makeWeeklySummaryInput(from: snapshot) : nil

        let resolved = await contentRefreshCoordinator.resolveWeeklySummary(
            templateSummary: templateSummary,
            input: input,
            dataState: snapshot.dataState,
            asOf: generatedAt
        )

        guard let resolved else { return snapshot }
        return snapshotWithSummary(resolved, from: snapshot)
    }

    func withResolvedObservations(
        from snapshot: InsightsSnapshot,
        generatedAt: Date
    ) async -> InsightsSnapshot {
        let templateObservations = snapshot.observations
        let candidates = makeObservationCandidates(from: snapshot)
        let input: InsightsObservationsGenerationInput?

        if snapshot.dataState == .ready, !candidates.isEmpty {
            input = InsightsObservationsGenerationInput(
                periodLabel: snapshot.period.label,
                summaryBody: snapshot.summary?.body,
                candidates: candidates
            )
        } else {
            input = nil
        }

        let resolved = await contentRefreshCoordinator.resolveObservations(
            templateObservations: templateObservations,
            input: input,
            dataState: snapshot.dataState,
            asOf: generatedAt
        )

        return snapshotWithObservations(resolved, from: snapshot)
    }

    func makeObservationCandidates(from snapshot: InsightsSnapshot) -> [InsightsObservationCandidate] {
        snapshot.observations
            .filter { $0.source == .template }
            .sorted { lhs, rhs in
                if lhs.priority == rhs.priority {
                    return lhs.generatedAt > rhs.generatedAt
                }
                return lhs.priority < rhs.priority
            }
            .prefix(4)
            .map {
                InsightsObservationCandidate(
                    title: $0.title,
                    body: $0.body,
                    signalKinds: $0.signalKinds,
                    priority: $0.priority
                )
            }
    }

    func withSelectedFactoids(
        from snapshot: InsightsSnapshot,
        generatedAt: Date
    ) -> InsightsSnapshot {
        let selectedForFullScreen = factoidSelector.selectFactoids(
            from: snapshot.factoids,
            dataState: snapshot.dataState,
            asOf: generatedAt
        )

        return snapshotWithFactoids(selectedForFullScreen, from: snapshot)
    }

    func makeWeeklySummaryInput(from snapshot: InsightsSnapshot) -> InsightsWeeklySummaryInput? {
        guard let momentsLogged = factoidValue(for: .momentsLogged, in: snapshot),
              let stayedPresentRate = factoidValue(for: .stayedPresentRate, in: snapshot) else {
            return nil
        }

        let dominantTimeWindow = snapshot.timePattern?.primaryBucket?.label
        let mostCommonUrge = factoidValue(for: .mostCommonUrge, in: snapshot)
        let topTag = factoidValue(for: .topTag, in: snapshot)
        let changeFactoid = factoidValue(for: .changeVsLastWeek, in: snapshot)
        let change: String?
        if let changeFactoid, changeFactoid != "—" {
            change = changeFactoid
        } else {
            change = nil
        }

        return InsightsWeeklySummaryInput(
            periodLabel: snapshot.period.label,
            momentsLogged: momentsLogged,
            stayedPresentRate: stayedPresentRate,
            dominantTimeWindow: dominantTimeWindow,
            mostCommonUrge: mostCommonUrge,
            topTag: topTag,
            changeVsPreviousPeriod: change
        )
    }

    func factoidValue(for kind: InsightFactoidKind, in snapshot: InsightsSnapshot) -> String? {
        if let factoid = snapshot.factoids.first(where: { $0.kind == kind && $0.isEligible }) {
            return factoid.valueText
        }
        return nil
    }

    func snapshotWithSummary(_ summary: InsightsSummary, from snapshot: InsightsSnapshot) -> InsightsSnapshot {
        InsightsSnapshot(
            period: snapshot.period,
            summary: summary,
            factoids: snapshot.factoids,
            activitySeries: snapshot.activitySeries,
            timePattern: snapshot.timePattern,
            observations: snapshot.observations,
            topTags: snapshot.topTags,
            urgeBreakdown: snapshot.urgeBreakdown,
            dataState: snapshot.dataState,
            lastRefreshedAt: snapshot.lastRefreshedAt
        )
    }

    func snapshotWithObservations(
        _ observations: [InsightObservation],
        from snapshot: InsightsSnapshot
    ) -> InsightsSnapshot {
        InsightsSnapshot(
            period: snapshot.period,
            summary: snapshot.summary,
            factoids: snapshot.factoids,
            activitySeries: snapshot.activitySeries,
            timePattern: snapshot.timePattern,
            observations: observations,
            topTags: snapshot.topTags,
            urgeBreakdown: snapshot.urgeBreakdown,
            dataState: snapshot.dataState,
            lastRefreshedAt: snapshot.lastRefreshedAt
        )
    }

    func snapshotWithFactoids(
        _ factoids: [InsightFactoid],
        from snapshot: InsightsSnapshot
    ) -> InsightsSnapshot {
        InsightsSnapshot(
            period: snapshot.period,
            summary: snapshot.summary,
            factoids: factoids,
            activitySeries: snapshot.activitySeries,
            timePattern: snapshot.timePattern,
            observations: snapshot.observations,
            topTags: snapshot.topTags,
            urgeBreakdown: snapshot.urgeBreakdown,
            dataState: snapshot.dataState,
            lastRefreshedAt: snapshot.lastRefreshedAt
        )
    }
}
