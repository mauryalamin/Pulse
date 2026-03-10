//
//  InsightFactoid.swift
//  Pulse
//
//  Created by Codex on 3/10/26.
//

import Foundation

/// A single "By the Numbers" insight item.
struct InsightFactoid: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let kind: InsightFactoidKind
    let title: String
    let valueText: String
    let subtitle: String?
    /// Lower values can be treated as higher display priority.
    let priority: Int
    /// Indicates whether this factoid has enough data to be shown.
    let isEligible: Bool

    init(
        id: UUID = UUID(),
        kind: InsightFactoidKind,
        title: String,
        valueText: String,
        subtitle: String? = nil,
        priority: Int,
        isEligible: Bool
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.valueText = valueText
        self.subtitle = subtitle
        self.priority = priority
        self.isEligible = isEligible
    }
}

/// Supported factoid types for the teaser module and full Insights screen.
enum InsightFactoidKind: String, CaseIterable, Hashable, Codable, Sendable {
    case momentsLogged
    case stayedPresentRate
    case stayedPresentCount
    case averageIntensity
    case mostCommonTimeWindow
    case mostCommonUrge
    case topTag
    case changeVsLastWeek
    case mostActiveDay
    case commonLocationType
    case highestIntensityPeriod
}
