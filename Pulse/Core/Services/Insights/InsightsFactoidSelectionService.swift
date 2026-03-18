//
//  InsightsFactoidSelectionService.swift
//  Pulse
//
//  Created by Codex on 3/16/26.
//

import Foundation

protocol InsightsFactoidSelecting {
    func selectFactoids(
        from candidates: [InsightFactoid],
        dataState: InsightsDataState,
        asOf date: Date
    ) -> [InsightFactoid]

    func teaserFactoids(from selectedForFullScreen: [InsightFactoid]) -> [InsightFactoid]
}

final class InsightsFactoidSelectionService: InsightsFactoidSelecting {
    private let maxFullScreenFactoids = 4
    private let maxTeaserFactoids = 3
    private let freshnessWindow: TimeInterval = 24 * 60 * 60
    private let recentPenaltyWindow: TimeInterval = 72 * 60 * 60

    private let defaults: UserDefaults
    private let storageKey = "pulse.insights.factoidSelectionState"

    private var state: SelectionState

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.state = SelectionState()
        self.state = loadState()
    }

    func selectFactoids(
        from candidates: [InsightFactoid],
        dataState: InsightsDataState,
        asOf date: Date
    ) -> [InsightFactoid] {
        let eligible = candidates
            .filter(\.isEligible)
            .sorted(by: factoidOrder)

        guard !eligible.isEmpty else { return [] }

        // For non-ready states, keep behavior simple and deterministic.
        if dataState != .ready {
            return Array(eligible.prefix(maxFullScreenFactoids))
        }

        let fingerprint = candidateFingerprint(for: eligible)

        if shouldReuseSelection(fingerprint: fingerprint, asOf: date),
           let reused = reuseSelection(from: eligible),
           !reused.isEmpty {
            return reused
        }

        let selected = chooseFactoids(from: eligible, asOf: date)

        state.lastCandidateFingerprint = fingerprint
        state.lastSelectedAt = date
        state.lastSelectedKinds = selected.map(\.kind)

        for factoid in selected {
            var metadata = state.kindMetadata[factoid.kind, default: KindMetadata()]
            metadata.lastShownAt = date
            metadata.shownCount += 1
            state.kindMetadata[factoid.kind] = metadata
        }

        saveState()
        return selected
    }

    func teaserFactoids(from selectedForFullScreen: [InsightFactoid]) -> [InsightFactoid] {
        selectedForFullScreen
            .sorted(by: factoidOrder)
            .prefix(maxTeaserFactoids)
            .map { $0 }
    }
}

private extension InsightsFactoidSelectionService {
    func factoidOrder(_ lhs: InsightFactoid, _ rhs: InsightFactoid) -> Bool {
        if lhs.priority == rhs.priority {
            return lhs.kind.rawValue < rhs.kind.rawValue
        }
        return lhs.priority < rhs.priority
    }

    func shouldReuseSelection(fingerprint: String, asOf date: Date) -> Bool {
        guard state.lastCandidateFingerprint == fingerprint,
              let lastSelectedAt = state.lastSelectedAt else {
            return false
        }

        return date.timeIntervalSince(lastSelectedAt) < freshnessWindow
    }

    func reuseSelection(from eligible: [InsightFactoid]) -> [InsightFactoid]? {
        let byKind = Dictionary(uniqueKeysWithValues: eligible.map { ($0.kind, $0) })

        let selected = state.lastSelectedKinds.compactMap { byKind[$0] }
        guard !selected.isEmpty else { return nil }

        return Array(selected.prefix(maxFullScreenFactoids))
    }

    func chooseFactoids(from eligible: [InsightFactoid], asOf date: Date) -> [InsightFactoid] {
        var chosen: [InsightFactoid] = []
        let categoriesByKind = Dictionary(uniqueKeysWithValues: InsightFactoidKind.allCases.map { ($0, $0.category) })

        if let anchor = eligible.first(where: { $0.kind.isAnchor }) {
            chosen.append(anchor)
        }

        while chosen.count < maxFullScreenFactoids {
            let remaining = eligible.filter { candidate in
                !chosen.contains(where: { $0.kind == candidate.kind })
            }

            guard !remaining.isEmpty else { break }

            let selectedCategories = Set(chosen.compactMap { categoriesByKind[$0.kind] })
            let hasNonAnchorOption = remaining.contains { !$0.kind.isAnchor }

            let ranked = remaining
                .map { candidate in
                    let score = selectionScore(
                        candidate,
                        selected: chosen,
                        selectedCategories: selectedCategories,
                        hasNonAnchorOption: hasNonAnchorOption,
                        asOf: date
                    )
                    return (candidate, score)
                }
                .sorted { lhs, rhs in
                    if lhs.1 == rhs.1 {
                        return factoidOrder(lhs.0, rhs.0)
                    }
                    return lhs.1 > rhs.1
                }

            guard let next = ranked.first?.0 else { break }
            chosen.append(next)
        }

        return Array(chosen.prefix(maxFullScreenFactoids))
    }

    func selectionScore(
        _ candidate: InsightFactoid,
        selected: [InsightFactoid],
        selectedCategories: Set<FactoidCategory>,
        hasNonAnchorOption: Bool,
        asOf date: Date
    ) -> Double {
        var score = 100.0 - Double(candidate.priority)

        let category = candidate.kind.category
        if !selectedCategories.contains(category) {
            score += 12
        }

        if candidate.kind.isAnchor,
           selected.contains(where: { $0.kind.isAnchor }),
           hasNonAnchorOption {
            score -= 25
        }

        if selected.contains(where: { $0.kind.redundancyGroup == candidate.kind.redundancyGroup }) {
            let hasAlternativeGroup = selected.count < maxFullScreenFactoids
            if hasAlternativeGroup {
                score -= 16
            }
        }

        if let metadata = state.kindMetadata[candidate.kind] {
            score -= Double(metadata.shownCount) * 0.6

            if !candidate.kind.isAnchor,
               let lastShownAt = metadata.lastShownAt,
               date.timeIntervalSince(lastShownAt) < recentPenaltyWindow {
                score -= 12
            }
        }

        return score
    }

    func candidateFingerprint(for eligible: [InsightFactoid]) -> String {
        eligible
            .map {
                [
                    $0.kind.rawValue,
                    String($0.priority),
                    $0.valueText,
                    $0.subtitle ?? ""
                ].joined(separator: "|")
            }
            .joined(separator: "||")
    }

    func loadState() -> SelectionState {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(SelectionState.self, from: data) else {
            return SelectionState()
        }
        return decoded
    }

    func saveState() {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: storageKey)
    }
}

private extension InsightFactoidKind {
    var category: FactoidCategory {
        switch self {
        case .momentsLogged, .stayedPresentRate, .stayedPresentCount:
            return .anchor
        case .mostCommonTimeWindow, .mostActiveDay:
            return .timing
        case .averageIntensity, .highestIntensityPeriod:
            return .intensity
        case .topTag, .commonLocationType:
            return .context
        case .changeVsLastWeek:
            return .trend
        case .mostCommonUrge:
            return .urgeType
        }
    }

    var isAnchor: Bool {
        switch self {
        case .momentsLogged, .stayedPresentRate, .stayedPresentCount:
            return true
        default:
            return false
        }
    }

    var redundancyGroup: FactoidRedundancyGroup {
        switch self {
        case .stayedPresentRate, .stayedPresentCount:
            return .response
        case .mostCommonTimeWindow, .mostActiveDay:
            return .timing
        case .averageIntensity, .highestIntensityPeriod:
            return .intensity
        case .topTag, .commonLocationType:
            return .context
        case .momentsLogged:
            return .volume
        case .mostCommonUrge:
            return .urge
        case .changeVsLastWeek:
            return .trend
        }
    }
}

private enum FactoidCategory: String, Codable, Sendable {
    case anchor
    case timing
    case intensity
    case context
    case trend
    case urgeType
}

private enum FactoidRedundancyGroup: String, Codable, Sendable {
    case volume
    case response
    case timing
    case intensity
    case context
    case trend
    case urge
}

private struct SelectionState: Codable, Sendable {
    var lastCandidateFingerprint: String?
    var lastSelectedAt: Date?
    var lastSelectedKinds: [InsightFactoidKind] = []
    var kindMetadata: [InsightFactoidKind: KindMetadata] = [:]
}

private struct KindMetadata: Codable, Sendable {
    var lastShownAt: Date?
    var shownCount: Int = 0
}
