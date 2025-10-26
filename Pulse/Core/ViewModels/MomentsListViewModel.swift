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

    // MARK: - Infra
    @ObservationIgnored private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
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
            self.moments = applyClientFilters(to: serverResults)
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
