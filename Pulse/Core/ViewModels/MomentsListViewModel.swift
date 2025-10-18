//
//  MomentsListViewModel.swift
//  Pulse
//
//  Created by Maury Alamin on 10/17/25.
//

import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class MomentsListViewModel {
    // MARK: Filters (UI state)
    var searchText: String = ""
    /// Store selected Urges by their SwiftData identifiers so it's stable across contexts.
    var selectedUrges: Set<PersistentIdentifier> = []
    var minIntensity: Int = 1
    var maxIntensity: Int = 5
    var stayedPresentOnly: Bool = false

    @ObservationIgnored private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - SwiftData predicate (keep it simple & fast)
    /// Only include things SwiftData predicates are happy with.
    var predicate: Predicate<Moment> {
        let minI = minIntensity
        let maxI = maxIntensity
        let stayedOnly = stayedPresentOnly

        return #Predicate<Moment> { m in
            // Intensity range
            (m.intensity >= minI && m.intensity <= maxI)
            // Stayed-present toggle (m.gaveIn == false)
            && (!stayedOnly || m.gaveIn == false)
        }
    }

    // MARK: - Post-query client-side filters (urge selection + search)
    func applyClientFilters(to moments: [Moment]) -> [Moment] {
        var filtered = moments

        // Urge filter via PersistentIdentifier (safe outside predicate)
        if !selectedUrges.isEmpty {
            filtered = filtered.filter { m in
                selectedUrges.contains(m.urge.id)
            }
        }

        // Text search across note + urge name
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            filtered = filtered.filter { m in
                (m.note?.localizedCaseInsensitiveContains(q) ?? false)
                || m.urge.name.localizedCaseInsensitiveContains(q)
            }
        }

        return filtered
    }

    // MARK: - Helpers for binding UI selections
    func toggleUrgeSelection(_ urge: Urge) {
        let id = urge.id
        if selectedUrges.contains(id) {
            selectedUrges.remove(id)
        } else {
            selectedUrges.insert(id)
        }
    }

    func isUrgeSelected(_ urge: Urge) -> Bool {
        selectedUrges.contains(urge.id)
    }
}
